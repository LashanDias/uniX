import assert from 'node:assert/strict';
const host=process.env.FIRESTORE_EMULATOR_HOST;
assert.match(host??'',/^(127\.0\.0\.1|localhost):\d+$/);
const project='demo-unix-recruiter';
const base=`http://${host}/v1/projects/${project}/databases/(default)/documents`;
function token(uid) { const enc=o=>Buffer.from(JSON.stringify(o)).toString('base64url'); const now=Math.floor(Date.now()/1000); return `${enc({alg:'none',typ:'JWT'})}.${enc({sub:uid,user_id:uid,email:`${uid}@sltc.ac.lk`,iat:now,exp:now+3600,aud:project,iss:`https://securetoken.google.com/${project}`,firebase:{sign_in_provider:'password'}})}.`; }
const headers=uid=>({'Content-Type':'application/json',Authorization:`Bearer ${uid==='admin-emulator'?'owner':token(uid)}`});
async function seed(path,data) { return fetch(`${base}/${path}`,{method:'PATCH',headers:headers('admin-emulator'),body:JSON.stringify({fields:Object.fromEntries(Object.entries(data).map(([k,v])=>[k,{stringValue:v}]))})}); }
await seed('lostFound/rules-active',{userId:'owner',status:'active',title:'Wallet'});
await seed('lostFound/rules-resolved',{userId:'owner',status:'resolved',title:'Wallet'});
await seed('users/owner/notifications/lostFound_rules-active',{itemId:'rules-active',userId:'owner'});
for(const uid of ['owner','another']) assert.equal((await fetch(`${base}/lostFound/rules-active`,{headers:headers(uid)})).status,200);
assert.equal((await fetch(`${base}/lostFound/rules-resolved`,{headers:headers('owner')})).status,200);
assert.equal((await fetch(`${base}/lostFound/rules-resolved`,{headers:headers('another')})).status,403);
for(const uid of ['owner','another']) {
 assert.equal((await fetch(`${base}/lostFound/rules-active`,{method:'PATCH',headers:headers(uid),body:JSON.stringify({fields:{status:{stringValue:'resolved'}}})})).status,403);
 assert.equal((await fetch(`${base}/lostFound/rules-active`,{method:'DELETE',headers:headers(uid)})).status,403);
}
assert.equal((await fetch(`${base}/users/owner/notifications/lostFound_rules-active`,{headers:headers('owner')})).status,200);
assert.equal((await fetch(`${base}/users/owner/notifications/lostFound_rules-active`,{headers:headers('another')})).status,403);
console.log('Lost & Found Firestore access rules passed.');
