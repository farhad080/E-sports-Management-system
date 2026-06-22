const express = require('express');
const path = require('path');
const session = require('express-session');
const methodOverride = require('method-override');
require('dotenv').config();

const db = require('./db/connection');
const routes = require('./routes/index');
const authRoutes = require('./routes/auth');
const errorHandler = require('./middlewares/errorHandler');

const app = express();
const PORT = process.env.PORT || 3000;

// Setup View Engine (EJS)
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// Body Parser Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Method Override (to allow PUT/DELETE requests via forms)
app.use(methodOverride('_method'));

// Session Middleware
app.use(session({
  secret: process.env.SESSION_SECRET || 'nexus_esports_secret',
  resave: false,
  saveUninitialized: false,
  cookie: { 
    secure: process.env.NODE_ENV === 'production',
    maxAge: 1000 * 60 * 60 * 24 // 24 hours
  }
}));

// Serve Static Files
app.use(express.static(path.join(__dirname, 'public')));

// Lightweight Custom EJS Layout Renderer Middleware
// This intercepts res.render, renders the target view into `body`, and wraps it in layout.ejs
app.use((req, res, next) => {
  const originalRender = res.render;
  
  res.render = function(view, options = {}, callback) {
    let self = this;
    let done = callback;
    let opts = options;
    
    // Support omission of options argument
    if (typeof options === 'function') {
      done = options;
      opts = {};
    }
    
    // Allow explicitly skipping layout by passing layout: false
    if (opts.layout === false) {
      return originalRender.call(self, view, opts, done);
    }
    
    // First render the core page content view
    req.app.render(view, opts, (err, pageHtml) => {
      if (err) {
        if (done) return done(err);
        return next(err);
      }
      
      // Inject page HTML into the main layout template as local variable 'body'
      const layoutData = { 
        ...opts, 
        body: pageHtml,
        user: req.session.user || null,
        success_msg: req.session.success_msg || '',
        error_msg: req.session.error_msg || ''
      };
      
      // Render layout.ejs
      if (done) {
        req.app.render('layout', layoutData, done);
      } else {
        req.app.render('layout', layoutData, (err, finalHtml) => {
          if (err) return next(err);
          self.send(finalHtml);
        });
      }
    });
  };
  
  next();
});

// App Routes
app.use('/', routes);
app.use('/', authRoutes);

// Error Handling Middleware
app.use(errorHandler);

// Connect to Oracle Database & Start Server
async function startServer() {
  try {
    // Attempt database initialization
    await db.initialize();
  } catch (err) {
    console.warn('WARNING: Application started WITHOUT active Oracle DB pool (check .env credentials).');
  }

  app.listen(PORT, () => {
    console.log(`==================================================`);
    console.log(` NEXUS eSPORTS TOURNAMENT MANAGEMENT SYSTEM RUNNING `);
    console.log(` Port: ${PORT} | Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(` URL: http://localhost:${PORT}`);
    console.log(`==================================================`);
  });
}

// Graceful Shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received. Shutting down gracefully...');
  await db.close();
  process.exit(0);
});

startServer();
