const stopWords = new Set(
  'a an and are as at be been being but by can could did do does for from had has have he her hers him his i if in into is it its may me might more most my no not of on or our ours she should so than that the their theirs them then there these they this those to too up us very was we were what when where which who will with would you your yours'.split(' '),
);

const conceptByWord = new Map();
const phraseAliases = [];

function stem(word) {
  if (word.length > 5 && word.endsWith('ies')) return `${word.slice(0, -3)}y`;
  if (word.length > 6 && word.endsWith('ing')) {
    let root = word.slice(0, -3);
    if (/(.)\1$/.test(root)) root = root.slice(0, -1);
    return root;
  }
  if (word.length > 5 && word.endsWith('ed')) {
    let root = word.slice(0, -2);
    if (/(.)\1$/.test(root)) root = root.slice(0, -1);
    return root;
  }
  if (word.length > 5 && word.endsWith('es')) return word.slice(0, -2);
  if (word.length > 4 && word.endsWith('s')) return word.slice(0, -1);
  return word;
}

function normalizeConceptWord(word) {
  return stem(
    word
      .toLowerCase()
      .normalize('NFKD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9+#.]/g, ''),
  );
}

function addConcept(name, words) {
  const key = String(name)
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '');
  if (!key || !Array.isArray(words)) return;

  const aliases = new Set([key.replace(/_/g, ' '), ...words.map(String)]);
  for (const alias of aliases) {
    const normalized = alias.toLowerCase().trim();
    if (normalized.includes(' ')) {
      phraseAliases.push({ phrase: normalized, concept: key });
    } else {
      const token = normalizeConceptWord(normalized);
      if (token) conceptByWord.set(token, key);
    }
  }
}

addConcept('leadership', [
  'lead', 'leads', 'led', 'leading', 'leader', 'leaders', 'manage', 'manages',
  'managed', 'manager', 'managing', 'mentor', 'mentors', 'mentored',
  'mentoring', 'team', 'teamwork',
]);
addConcept('data', [
  'sql', 'database', 'databases', 'postgres', 'postgresql', 'mysql',
  'analytics', 'analysis', 'analyst', 'reporting', 'query', 'queries',
]);
addConcept('frontend', [
  'react', 'reactjs', 'javascript', 'js', 'typescript', 'frontend', 'front end',
]);

function tokenize(value) {
  let text = String(value ?? '')
    .toLowerCase()
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '');

  for (const { phrase, concept } of phraseAliases) {
    const escaped = phrase.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    text = text.replace(new RegExp(`\\b${escaped}\\b`, 'g'), ` ${concept} `);
  }

  return (text.match(/[a-z0-9_+#.]+/g) ?? [])
    .map(stem)
    .filter((word) => word && !stopWords.has(word))
    .map((word) => conceptByWord.has(word)
      ? `concept:${conceptByWord.get(word)}`
      : word.startsWith('concept_')
        ? `concept:${word.slice('concept_'.length)}`
        : word);
}

function requirementText(requirement) {
  if (typeof requirement === 'string') return requirement;
  return [requirement?.title, requirement?.text ?? requirement?.requirement]
    .filter(Boolean)
    .join('. ');
}

function cosine(left, right) {
  if (left.size === 0 || right.size === 0) return 0;
  let dot = 0;
  let leftSquares = 0;
  let rightSquares = 0;
  for (const value of left.values()) leftSquares += value * value;
  for (const value of right.values()) rightSquares += value * value;
  for (const [word, value] of left) dot += value * (right.get(word) ?? 0);
  return leftSquares && rightSquares
    ? dot / (Math.sqrt(leftSquares) * Math.sqrt(rightSquares))
    : 0;
}

function matchOne(cvText, requirement) {
  const text = requirementText(requirement);
  const requiredTokens = tokenize(text);
  const requiredTerms = new Set(requiredTokens);
  const cvTokens = tokenize(cvText);
  const cvTerms = new Set(cvTokens);
  const coverage = requiredTerms.size === 0
    ? 0
    : [...requiredTerms].filter((term) => cvTerms.has(term)).length / requiredTerms.size;
  const requiredVector = new Map();
  for (const word of requiredTokens) {
    requiredVector.set(word, (requiredVector.get(word) ?? 0) + 1);
  }

  const sentences = String(cvText ?? '')
    .split(/(?<=[.!?])\s+|\r?\n+/)
    .map((sentence) => sentence.trim())
    .filter(Boolean);
  let evidence = '';
  let bestSimilarity = 0;
  for (const sentence of sentences) {
    const vector = new Map();
    for (const word of tokenize(sentence)) {
      vector.set(word, (vector.get(word) ?? 0) + 1);
    }
    const similarity = cosine(requiredVector, vector);
    if (similarity > bestSimilarity) {
      bestSimilarity = similarity;
      evidence = sentence;
    }
  }

  const score = Math.max(0, Math.min(100, Math.round(
    100 * (0.6 * coverage + 0.4 * bestSimilarity),
  )));
  return {
    requirement: text,
    score,
    label: score >= 60 ? 'Strong' : score >= 30 ? 'Partial' : 'Gap',
    evidence,
  };
}

export function matchCV(cvText, requirements) {
  const items = (Array.isArray(requirements) ? requirements : [])
    .map((requirement) => matchOne(cvText, requirement));
  const total = items.length === 0
    ? 0
    : Math.round(items.reduce((sum, item) => sum + item.score, 0) / items.length);
  return { total, items };
}

export { addConcept };
