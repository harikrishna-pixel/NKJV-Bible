const fs = require('fs');
const path = require('path');
const express = require('express');
const multer = require('multer');

const PORT = Number(process.env.PORT || 3000);
const root = path.join(__dirname, '..');
const dataDir = path.join(root, 'data');
const uploadDir = path.join(root, 'uploads');
const storePath = path.join(dataDir, 'store.json');

fs.mkdirSync(dataDir, { recursive: true });
fs.mkdirSync(uploadDir, { recursive: true });

function load() {
  try {
    return JSON.parse(fs.readFileSync(storePath, 'utf8'));
  } catch (_) {
    return { questions: [], tickets: [], knowledges: [], applications: [] };
  }
}

function save(store) {
  fs.writeFileSync(storePath, JSON.stringify(store, null, 2));
}

function id() {
  return `${Date.now().toString(16)}${Math.random().toString(16).slice(2, 10)}`;
}

const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadDir),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname || '').toLowerCase() || '.png';
      cb(null, `${Date.now()}-${Math.random().toString(16).slice(2, 8)}${ext}`);
    },
  }),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const ok = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.mimetype);
    cb(ok ? null : new Error('Only jpeg, png, webp, and gif images are allowed'), ok);
  },
});

const app = express();
app.use(express.json());
app.use('/uploads', express.static(uploadDir));

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.put('/api/upload', (req, res) => {
  upload.single('image')(req, res, (err) => {
    if (err) {
      const tooBig = err.code === 'LIMIT_FILE_SIZE';
      return res.status(400).json({
        message: tooBig ? 'Image must be 5MB or smaller' : (err.message || 'image file is required'),
      });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'image file is required' });
    }
    const objectUrl = `http://localhost:${PORT}/uploads/${req.file.filename}`;
    res.json({ message: 'Image uploaded', data: { objectUrl } });
  });
});

app.get('/api/questions', (req, res) => {
  const userId = String(req.query.userId || '').trim();
  if (!userId) return res.status(400).json({ message: 'userId query param is required' });
  const store = load();
  const data = store.questions.filter((q) => q.userId === userId);
  res.json({ message: 'User questions fetched', data });
});

app.post('/api/questions', (req, res) => {
  const userId = String(req.body.userId || '').trim();
  const appName = String(req.body.appName || '').trim();
  const bundleId = String(req.body.bundleId || '').trim();
  const question = String(req.body.question || '').trim();
  const imageUrl = String(req.body.imageUrl || '').trim();
  if (!userId || !appName || !bundleId || !question) {
    return res.status(400).json({
      message: 'userId, appName, bundleId, and question are required',
    });
  }

  const store = load();
  const questionId = id();
  const ticketId = id();
  const userQuestion = {
    _id: questionId,
    userId,
    appName,
    bundleId,
    question,
    answer: '',
    imageUrl,
    status: 'open',
    answeredBy: 'human',
    ticketId,
  };
  const ticket = {
    _id: ticketId,
    userId,
    appName,
    bundleId,
    userQuestionId: questionId,
    question,
    answer: '',
    imageUrl,
    status: 'open',
    answeredBy: 'human',
    aiAnswer: '',
  };
  store.questions.push(userQuestion);
  store.tickets.push(ticket);
  save(store);
  res.status(201).json({
    message: 'Question submitted and ticket created',
    data: { resolvedBy: 'human', userQuestion, ticket },
  });
});

app.post('/api/questions/:id/escalate', (req, res) => {
  const userId = String(req.body.userId || '').trim();
  if (!userId) return res.status(400).json({ message: 'userId is required' });
  const store = load();
  const userQuestion = store.questions.find((q) => q._id === req.params.id && q.userId === userId);
  if (!userQuestion) return res.status(404).json({ message: 'Question not found' });
  if (userQuestion.answeredBy !== 'ai') {
    return res.status(400).json({ message: 'Only questions answered by AI can be escalated' });
  }
  const ticket = store.tickets.find((t) => t._id === userQuestion.ticketId);
  userQuestion.answer = '';
  userQuestion.status = 'open';
  userQuestion.answeredBy = 'human';
  if (ticket) {
    ticket.aiAnswer = ticket.aiAnswer || ticket.answer;
    ticket.answer = '';
    ticket.status = 'open';
    ticket.answeredBy = 'human';
  }
  save(store);
  res.json({
    message: 'Question escalated to support',
    data: { userQuestion, ticket },
  });
});

app.get('/api/tickets', (req, res) => {
  const status = String(req.query.status || '').trim();
  const store = load();
  const data = status ? store.tickets.filter((t) => t.status === status) : store.tickets;
  res.json({ message: 'Tickets fetched', data });
});

app.post('/api/tickets/:id/reply', (req, res) => {
  const answer = String(req.body.answer || '').trim();
  if (!answer) return res.status(400).json({ message: 'answer is required' });
  const store = load();
  const ticket = store.tickets.find((t) => t._id === req.params.id);
  if (!ticket) return res.status(404).json({ message: 'Ticket not found' });
  if (ticket.status === 'closed') {
    return res.status(400).json({ message: 'Ticket is already closed' });
  }
  ticket.answer = answer;
  ticket.status = 'closed';
  ticket.answeredBy = 'human';
  const userQuestion = store.questions.find((q) => q._id === ticket.userQuestionId);
  if (userQuestion) {
    userQuestion.answer = answer;
    userQuestion.status = 'closed';
    userQuestion.answeredBy = 'human';
  }
  save(store);
  res.json({
    message: 'Answer saved, user record updated, ticket closed',
    data: { ticket, userQuestion },
  });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Support server listening on http://127.0.0.1:${PORT}`);
});
