const {test} = require('node:test');
const assert = require('node:assert/strict');
const {DAY,newPost,respond,due,question,repository} = require('../src/lost_found');
const input = {itemId:'wallet1',title:'Black Wallet',location:'Library',description:'Black leather wallet',type:'lost',category:'Wallet',images:[]};
function post(type='lost') { return newPost({...input,type},'owner',0); }
function ask(p,now) { assert.equal(due(p,now),true); return {...p,awaitingResponse:true,checkToken:`check-${now}`,lastCheckAt:now,nextCheckAt:null}; }
function answer(p,action,now,uid='owner') { return {...p,...respond(p,uid,{action,checkToken:p.checkToken},now)}; }
for (const type of ['lost','found']) {
 for (const noCount of [0,1,2,3]) test(`${type}: ${noCount} NO responses then YES`,()=>{
   let p=post(type), now=0;
   for(let i=0;i<noCount;i++) { now=p.nextCheckAt; p=ask(p,now); p=answer(p,'no',now); assert.equal(p.validationStage,[4,8,2][i]); assert.equal(p.nextCheckAt,now+p.validationStage*DAY); }
   now=p.nextCheckAt; p=ask(p,now); p=answer(p,'yes',now);
   assert.equal(p.status,'resolved'); assert.equal(p.resolvedAt,now); assert.equal(p.nextCheckAt,null); assert.equal(due(p,now+100*DAY),false);
 });
}
test('deleted, missing and resolved posts never become due',()=>{
 const p=post(); assert.equal(due(null,10*DAY),false);
 for(const action of ['resolve','delete']) { const done=answer(p,action,DAY); assert.equal(due(done,100*DAY),false); assert.equal(done.nextCheckAt,null); }
});
test('owner enforcement and stale/double answers',()=>{
 const p=ask(post(),2*DAY);
 for(const action of ['yes','no','resolve','delete']) assert.throws(()=>answer(p,action,2*DAY,'another-user'),{code:'permission-denied'});
 assert.throws(()=>respond(null,'owner',{action:'yes'},0),{code:'not-found'});
 assert.throws(()=>respond(p,'owner',{action:'no',checkToken:'stale'},2*DAY),{code:'failed-precondition'});
 const next=answer(p,'no',2*DAY); assert.throws(()=>answer(next,'no',2*DAY),{code:'failed-precondition'});
});
test('late response waits the next full interval; no answer does not advance',()=>{
 const p=ask(post(),3*DAY); assert.equal(due(p,100*DAY),false);
 assert.equal(answer(p,'no',10*DAY).nextCheckAt,14*DAY);
 assert.match(question(post('found')),/owner collected/);
});
test('server rejects invalid post fields',()=>{
 for(const patch of [{type:'other'},{title:''},{location:''},{category:'OtherInvalid'},{images:['not-an-image']},{title:'x'.repeat(151)}]) assert.throws(()=>newPost({...input,...patch},'owner',0),{code:'invalid-argument'});
 assert.throws(()=>newPost(input,null,0),{code:'unauthenticated'});
});

// Optional emulator integration uses the production repository and real transactions.
test('Firestore transactions: retries, concurrent schedules, ownership and cleanup', {skip: !process.env.FIRESTORE_EMULATOR_HOST}, async()=>{
 assert.match(process.env.FIRESTORE_EMULATOR_HOST,/^(127\.0\.0\.1|localhost):\d+$/);
 const {initializeApp}=require('firebase-admin/app'); const {getFirestore,Timestamp}=require('firebase-admin/firestore');
 const db=getFirestore(initializeApp({projectId:'demo-unix-recruiter'})); const repo=repository(db,Timestamp);
 const itemId=`integration-${Date.now()}`;
 await Promise.all([repo.create('owner',{...input,itemId},0),repo.create('owner',{...input,itemId},0)]);
 const scheduled=await Promise.all([repo.enqueue(itemId,2*DAY),repo.enqueue(itemId,2*DAY)]);
 assert.equal(scheduled.filter(Boolean).length,1);
 let p=(await db.doc(`lostFound/${itemId}`).get()).data();
 await assert.rejects(repo.answer('intruder',{itemId,action:'yes',checkToken:p.checkToken},2*DAY),{code:'permission-denied'});
 const answers=await Promise.allSettled([repo.answer('owner',{itemId,action:'no',checkToken:p.checkToken},2*DAY),repo.answer('owner',{itemId,action:'no',checkToken:p.checkToken},2*DAY)]);
 assert.equal(answers.filter(r=>r.status==='fulfilled').length,1);
 p=(await db.doc(`lostFound/${itemId}`).get()).data(); assert.equal(p.validationStage,4); assert.equal(p.nextCheckAt.toMillis(),6*DAY);
 await repo.runDue(6*DAY); p=(await db.doc(`lostFound/${itemId}`).get()).data(); assert.equal(p.awaitingResponse,true);
 await repo.answer('owner',{itemId,action:'yes',checkToken:p.checkToken},6*DAY);
 assert.equal(await repo.enqueue(itemId,100*DAY),false);
 assert.equal((await db.doc(`users/owner/notifications/lostFound_${itemId}`).get()).exists,false);
 const deleted=`deleted-${Date.now()}`; await repo.create('owner',{...input,itemId:deleted},0); await repo.enqueue(deleted,2*DAY); await db.doc(`lostFound/${deleted}`).delete(); await repo.cleanup(deleted,'owner');
 assert.equal(await repo.enqueue(deleted,100*DAY),false);
 assert.equal((await db.doc(`users/owner/notifications/lostFound_${deleted}`).get()).exists,false);
 await db.terminate();
});
