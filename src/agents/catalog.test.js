import test from 'node:test';
import assert from 'node:assert/strict';
import {triageIssue, bookingRecommendation, dispatchRecommendation, notificationPlan} from './catalog.js';

test('triage laptop', () => assert.equal(triageIssue('keyboard broken on laptop').category, 'laptop'));
test('triage mobile', () => assert.equal(triageIssue('iphone charging problem').category, 'mobile'));
test('triage desktop', () => assert.equal(triageIssue('desktop SSD upgrade').category, 'desktop'));
test('unknown issue stays unclassified', () => assert.equal(triageIssue('help please').category, null));
test('non-string triage input is safe', () => assert.equal(triageIssue(null).category, null));
test('swollen battery warning', () => assert.equal(triageIssue('battery swollen').urgent, true));
test('smoke warning', () => assert.equal(triageIssue('device smoke').urgent, true));
test('booking requires customer confirmation', () => assert.equal(bookingRecommendation().canWriteBookings, false));
test('dispatch matches availability and skill', () => {
  const techs = [{id:'a',available:true,skills:['mobile']},{id:'b',available:false,skills:['mobile']},{id:'c',available:true,skills:['laptop']}];
  assert.deepEqual(dispatchRecommendation({category:'mobile'},techs).map(t=>t.technicianId), ['a']);
});
test('dispatch handles missing technicians and booking', () => {
  assert.deepEqual(dispatchRecommendation(null, []), []);
  assert.deepEqual(dispatchRecommendation({category:'mobile'}, [{id:'x',available:true}]), []);
});
test('notifications are a plan, not an actual send', () => {
  assert.equal(notificationPlan({id:'booking-1'})[0].requiresProvider, true);
});
