const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ── helpers ──────────────────────────────────────────────────────────────────

async function getUserFcmToken(uid) {
  const doc = await db.collection('users').doc(uid).get();
  return doc.exists ? doc.data().fcmToken : null;
}

async function getManagerFcmToken(orgId) {
  const snap = await db.collection('users')
    .where('orgId', '==', orgId)
    .where('role', '==', 'manager')
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].data().fcmToken || null;
}

async function sendPush(token, title, body, data = {}) {
  if (!token) return;
  try {
    await messaging.send({
      token,
      notification: { title, body },
      data,
      android: { priority: 'high' },
    });
  } catch (e) {
    console.error('FCM send failed:', e.message);
  }
}

async function writeNotification(toUid, message, taskId, type) {
  await db.collection('notifications').add({
    toUid,
    message,
    taskId,
    type,
    read: false,
    createdAt: FieldValue.serverTimestamp(),
  });
}

// ── onTaskCreated: notify all assignees ──────────────────────────────────────

exports.onTaskCreated = onDocumentCreated('tasks/{taskId}', async (event) => {
  const task = event.data.data();
  const taskId = event.params.taskId;
  const assignedTo = task.assignedTo || [];
  const title = task.title || 'New task';

  await Promise.all(assignedTo.map(async (uid) => {
    const token = await getUserFcmToken(uid);
    const msg = `You have a new task: ${title}`;
    await sendPush(token, 'New Task Assigned', msg, { taskId });
    await writeNotification(uid, msg, taskId, 'task_assigned');
  }));
});

// ── onTaskUpdated: handle check-offs and full completion ──────────────────────

exports.onTaskUpdated = onDocumentUpdated('tasks/{taskId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const taskId = event.params.taskId;

  const prevCompleted = before.completedBy || [];
  const newCompleted = after.completedBy || [];
  const assignedTo = after.assignedTo || [];
  const taskTitle = after.title || 'Task';

  // find newly checked-off employees
  const newCheckoffs = newCompleted.filter((uid) => !prevCompleted.includes(uid));

  for (const uid of newCheckoffs) {
    const userDoc = await db.collection('users').doc(uid).get();
    const empName = userDoc.exists ? userDoc.data().name : uid;

    // notify manager
    const managerToken = await getManagerFcmToken(after.orgId);
    const allDone = after.status === 'completed';
    const msg = allDone
      ? `All employees completed: ${taskTitle}`
      : `${empName} completed their part of: ${taskTitle}`;

    // get manager uid for notification doc
    const managerSnap = await db.collection('users')
      .where('orgId', '==', after.orgId)
      .where('role', '==', 'manager')
      .limit(1)
      .get();
    if (!managerSnap.empty) {
      const managerUid = managerSnap.docs[0].id;
      await sendPush(managerToken, allDone ? 'Task Completed ✓' : 'Task Progress', msg, { taskId });
      await writeNotification(managerUid, msg, taskId, 'task_completed');
    }

    // if group task and not all done yet, notify remaining assignees
    if (!allDone && assignedTo.length > 1) {
      const remaining = assignedTo.filter((u) => !newCompleted.includes(u));
      await Promise.all(remaining.map(async (remUid) => {
        const token = await getUserFcmToken(remUid);
        const remMsg = `${empName} completed their part of: ${taskTitle}`;
        await sendPush(token, 'Team Task Update', remMsg, { taskId });
        await writeNotification(remUid, remMsg, taskId, 'task_assigned');
      }));
    }
  }
});

// ── scheduledReminders: daily 8am — overdue tasks ────────────────────────────

exports.scheduledReminders = onSchedule('0 8 * * *', async () => {
  const now = Timestamp.now();
  const snap = await db.collection('tasks')
    .where('dueDate', '<', now)
    .where('status', 'in', ['pending', 'in_progress'])
    .get();

  for (const doc of snap.docs) {
    const task = doc.data();
    const taskId = doc.id;
    const assignedTo = task.assignedTo || [];
    const title = task.title || 'Task';

    await Promise.all(assignedTo.map(async (uid) => {
      // only remind if this employee hasn't completed it
      if ((task.completedBy || []).includes(uid)) return;
      const token = await getUserFcmToken(uid);
      const msg = `Reminder: "${title}" is overdue`;
      await sendPush(token, 'Overdue Task', msg, { taskId });
      await writeNotification(uid, msg, taskId, 'reminder');
    }));
  }
});
