// Современный React-компонент для личного кабинета
// Для работы требуется: npm install react react-dom
// Сборка: npm install vite @vitejs/plugin-react -D

import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom/client';
import './styles.css';

const NAKAMA_BASE = 'http://localhost:7350';

function Dashboard() {
  const [user, setUser] = useState(null);
  const [sessionToken, setSessionToken] = useState(localStorage.getItem('session_token'));
  const [news, setNews] = useState([]);
  const [stats, setStats] = useState({
    level: 1,
    playtime: 0,
    islands: 1,
    achievements: 0
  });
  const [pearls, setPearls] = useState(0);
  const [loading, setLoading] = useState(true);
  const [showPayment, setShowPayment] = useState(false);

  useEffect(() => {
    if (sessionToken) {
      loadUserData();
    } else {
      setLoading(false);
    }
  }, [sessionToken]);

  async function loadUserData() {
    try {
      const resp = await fetch(`${NAKAMA_BASE}/v2/account`, {
        headers: { 'Authorization': `Bearer ${sessionToken}` }
      });
      if (resp.ok) {
        const data = await resp.json();
        setUser({
          id: data.user.id,
          username: data.user.username,
          email: data.user.email,
          avatar: data.user.avatar_url || ''
        });
        loadNews();
        loadStats();
        loadPearls();
      }
    } catch (e) {
      console.error('Failed to load user data:', e);
    } finally {
      setLoading(false);
    }
  }

  function loadNews() {
    // Заглушка - в реальной игре загружать с API
    setNews([
      {
        id: 1,
        title: 'Обновление 0.1.17 - Монетизация и донат магазин',
        content: 'Добавлена система монетизации с премиум-валютой Pearls, донат магазин с косметикой, питомцами и эмоциями!',
        date: '2024-12-05',
        type: 'update',
        isNew: true
      },
      {
        id: 2,
        title: 'Новый сезон: Пробуждение глубин',
        content: 'Открыт новый сезонный пропуск с уникальными наградами!',
        date: '2024-12-04',
        type: 'event',
        isNew: true
      }
    ]);
  }

  function loadStats() {
    // Заглушка - в реальной игре загружать с API
    setStats({
      level: 5,
      playtime: 3600,
      islands: 1,
      achievements: 3
    });
  }

  async function loadPearls() {
    // Загружаем баланс Pearls с сервера
    try {
      const resp = await fetch(`${NAKAMA_BASE}/v2/account`, {
        headers: { 'Authorization': `Bearer ${sessionToken}` }
      });
      if (resp.ok) {
        // TODO: Получить Pearls из storage или отдельного API
        setPearls(0);
      }
    } catch (e) {
      console.error('Failed to load pearls:', e);
    }
  }

  function handleBuyPearls(packageId) {
    // Открываем платежный шлюз
    window.location.href = `/payment?package=${packageId}&user_id=${user?.id}`;
  }

  if (loading) {
    return <div className="loading">Загрузка...</div>;
  }

  if (!user) {
    return <LoginForm onLogin={(token) => { setSessionToken(token); localStorage.setItem('session_token', token); }} />;
  }

  return (
    <div className="dashboard">
      <Header user={user} pearls={pearls} onLogout={() => { setSessionToken(null); localStorage.removeItem('session_token'); setUser(null); }} />
      <div className="main-content">
        <div className="news-panel">
          <h2>📰 Новости</h2>
          <NewsList news={news} />
        </div>
        <div className="sidebar">
          <StatsPanel stats={stats} />
          <PearlsPanel pearls={pearls} onBuyPearls={() => setShowPayment(true)} />
          <QuickActions />
        </div>
      </div>
      {showPayment && <PaymentModal onClose={() => setShowPayment(false)} onPurchase={handleBuyPearls} />}
    </div>
  );
}

function LoginForm({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  async function handleLogin(e) {
    e.preventDefault();
    try {
      const resp = await fetch(`${NAKAMA_BASE}/v2/account/authenticate/email?create=false`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      });
      const data = await resp.json();
      if (resp.ok && data.token) {
        onLogin(data.token);
      } else {
        setError('Ошибка входа. Проверьте email и пароль.');
      }
    } catch (e) {
      setError('Ошибка: ' + e.message);
    }
  }

  return (
    <div className="login-form">
      <h2>Вход в личный кабинет</h2>
      <form onSubmit={handleLogin}>
        <input type="email" placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} required />
        <input type="password" placeholder="Пароль" value={password} onChange={(e) => setPassword(e.target.value)} required />
        {error && <div className="error">{error}</div>}
        <button type="submit">Войти</button>
      </form>
      <a href="index.html">Нет аккаунта? Зарегистрироваться</a>
    </div>
  );
}

function Header({ user, pearls, onLogout }) {
  return (
    <header>
      <div className="logo">Isleborn Online</div>
      <div className="user-info">
        <div className="avatar">{user.username[0].toUpperCase()}</div>
        <div>
          <div className="username">{user.username}</div>
          <div className="email">{user.email}</div>
        </div>
        <div className="pearls">💎 {pearls}</div>
        <button onClick={onLogout}>Выйти</button>
      </div>
    </header>
  );
}

function NewsList({ news }) {
  return (
    <div className="news-list">
      {news.map(item => (
        <div key={item.id} className={`news-item ${item.isNew ? 'new' : ''}`}>
          <div className="news-header">
            <h3>{item.title}</h3>
            <span className={`badge badge-${item.type}`}>
              {item.type === 'update' ? 'ОБНОВЛЕНИЕ' : 'СОБЫТИЕ'}
            </span>
          </div>
          <p>{item.content}</p>
          <div className="news-date">{item.date}</div>
        </div>
      ))}
    </div>
  );
}

function StatsPanel({ stats }) {
  return (
    <div className="panel">
      <h2>📊 Статистика</h2>
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-value">{stats.level}</div>
          <div className="stat-label">Уровень</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{Math.floor(stats.playtime / 3600)}ч</div>
          <div className="stat-label">Игровое время</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{stats.islands}</div>
          <div className="stat-label">Острова</div>
        </div>
        <div className="stat-card">
          <div className="stat-value">{stats.achievements}</div>
          <div className="stat-label">Достижения</div>
        </div>
      </div>
    </div>
  );
}

function PearlsPanel({ pearls, onBuyPearls }) {
  return (
    <div className="panel pearls-panel">
      <h2>💎 Жемчужины</h2>
      <div className="pearls-amount">{pearls}</div>
      <button onClick={onBuyPearls} className="btn-primary">Купить Pearls</button>
    </div>
  );
}

function QuickActions() {
  return (
    <div className="panel">
      <h2>⚡ Быстрые действия</h2>
      <div className="quick-actions">
        <a href="#" className="btn btn-primary">Играть</a>
        <button className="btn btn-secondary">Обновить статистику</button>
        <button className="btn btn-secondary">Настройки</button>
        <button className="btn btn-secondary">Скачать клиент</button>
      </div>
    </div>
  );
}

function PaymentModal({ onClose, onPurchase }) {
  const packages = [
    { id: 'pearls_100', pearls: 100, price: 99, bonus: 0 },
    { id: 'pearls_500', pearls: 500, price: 399, bonus: 50 },
    { id: 'pearls_1000', pearls: 1000, price: 699, bonus: 150 },
    { id: 'pearls_2500', pearls: 2500, price: 1499, bonus: 500 }
  ];

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={(e) => e.stopPropagation()}>
        <button className="modal-close" onClick={onClose}>×</button>
        <h2>Покупка Жемчужин</h2>
        <div className="payment-packages">
          {packages.map(pkg => (
            <div key={pkg.id} className="payment-package" onClick={() => onPurchase(pkg.id)}>
              <div className="package-pearls">{pkg.pearls + (pkg.bonus > 0 ? ` + ${pkg.bonus}` : '')} 💎</div>
              <div className="package-price">{pkg.price} ₽</div>
              {pkg.bonus > 0 && <div className="package-bonus">Бонус +{pkg.bonus}!</div>}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

// Инициализация React приложения
if (document.getElementById('app')) {
  const root = ReactDOM.createRoot(document.getElementById('app'));
  root.render(<Dashboard />);
}

export default Dashboard;

