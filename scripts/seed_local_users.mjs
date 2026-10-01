import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const envPath = fileURLToPath(new URL('../.env', import.meta.url));
const env = Object.fromEntries((await readFile(envPath, 'utf8')).split(/\r?\n/).filter(line => line.trim() && !line.trim().startsWith('#')).map(line => {
  const at = line.indexOf('=');
  if (at < 1) throw new Error('Invalid .env entry');
  return [line.slice(0, at).trim(), line.slice(at + 1).trim().replace(/^(["'])(.*)\1$/, '$2')];
}));
// Deliberately fixed loopback endpoints and demo project: never seed production.
const auth = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const firestore = 'http://127.0.0.1:8089/v1/projects/demo-unix-local/databases/(default)/documents';
async function request(url, body, token) {
  const response = await fetch(url, {method: 'POST', headers: {'Content-Type':'application/json', ...(token ? {Authorization:`Bearer ${token}`} : {})}, body:JSON.stringify(body)});
  const data = await response.json();
  if (!response.ok) throw new Error(data.error?.message ?? `Local emulator returned ${response.status}`);
  return data;
}
for (const [key, name, role] of [['STUDENT','Test Student','Student'], ['RECRUITER','Test HR Recruiter','Recruiter']]) {
  const email = env[`UNIX_TEST_${key}_EMAIL`];
  const password = env[`UNIX_TEST_${key}_PASSWORD`];
  if (!email || !password || password.length < 6) throw new Error(`Set a valid ${key} email and password (6+ characters) in .env`);
  if (role === 'Student' && !email.endsWith('@sltc.ac.lk')) throw new Error('Test students need an @sltc.ac.lk address.');
  let account;
  try { account = await request(`${auth}/accounts:signUp?key=demo-api-key`, {email,password,returnSecureToken:true}); }
  catch (error) {
    if (!error.message.includes('EMAIL_EXISTS')) throw error;
    account = await request(`${auth}/accounts:signInWithPassword?key=demo-api-key`, {email,password,returnSecureToken:true});
  }
  await request(`${auth}/accounts:update?key=demo-api-key`, {idToken:account.idToken,displayName:name,returnSecureToken:true});
  const fields = Object.fromEntries(Object.entries({name,email,role}).map(([key,value]) => [key,{stringValue:value}]));
  await request(`${firestore}:commit`, {writes:[{update:{name:`projects/demo-unix-local/databases/(default)/documents/users/${account.localId}`,fields},updateMask:{fieldPaths:['name','email','role']},updateTransforms:[{fieldPath:'updatedAt',setToServerValue:'REQUEST_TIME'}]}]}, account.idToken);
  // Validate real password login and persisted role, without printing tokens/passwords.
  const login = await request(`${auth}/accounts:signInWithPassword?key=demo-api-key`, {email,password,returnSecureToken:true});
  const profile = await fetch(`${firestore}/users/${login.localId}`, {headers:{Authorization:`Bearer ${login.idToken}`}});
  const stored = await profile.json();
  if (!profile.ok || stored.fields?.role?.stringValue !== role) throw new Error(`Profile validation failed for ${role}`);
  console.log(`${role} account ready: ${email}`);
}
