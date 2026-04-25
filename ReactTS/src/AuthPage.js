import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { supabase } from './supabase';
import './App.css';

function AuthPage() {
  const navigate = useNavigate();
  const [isLogin, setIsLogin] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!isLogin && password.length < 6) {
      setMessage('Password must be at least 6 characters');
      return;
    }

    setLoading(true);
    setMessage('');

    try {
      if (isLogin) {
        // Login
        const { data, error } = await supabase.auth.signInWithPassword({
          email: email,
          password: password,
        });
        
        if (error) {
          setMessage('Login failed: ' + error.message);
        } else {
          setMessage('Login successful!');
          setTimeout(() => {
            navigate('/');
          }, 1000);
        }
      } else {
        // Signup
        const { data, error } = await supabase.auth.signUp({
          email: email,
          password: password,
        });
        
        if (error) {
          setMessage('Signup failed: ' + error.message);
        } else {
          setMessage('Check your email for verification link!');
          setTimeout(() => {
            setIsLogin(true);
            setEmail('');
            setPassword('');
            setMessage('');
          }, 2000);
        }
      }
    } catch (error) {
      setMessage('Error: ' + error.message);
    } finally {
      setLoading(false);
    }
  };

  const toggleMode = () => {
    setIsLogin(!isLogin);
    setEmail('');
    setPassword('');
    setMessage('');
  };

  return (
    <div className="App">
      <div className="header-container">
        <img src="/a.svg" alt="Amiya Health Logo" className="logo" />
        <h2 className="brand-name">amiya health</h2>
        <Link to="/" className="signup-button" style={{ textDecoration: 'none' }}>
          back to home
        </Link>
      </div>

      <div className="auth-container">
        <div className="auth-form">
          <div className="auth-toggle">
            <button 
              className={`toggle-button ${!isLogin ? 'active' : ''}`}
              onClick={() => setIsLogin(false)}
            >
              Sign Up
            </button>
            <button 
              className={`toggle-button ${isLogin ? 'active' : ''}`}
              onClick={() => setIsLogin(true)}
            >
              Sign In
            </button>
          </div>

          <h1>{isLogin ? 'Welcome Back' : 'Create Account'}</h1>
          <p>{isLogin ? 'Sign in to your Amiya Health account' : 'Join Amiya Health to get started'}</p>
          
          <form onSubmit={handleSubmit}>
            <div className="auth-input-wrapper">
              <span className="auth-input-label">Email</span>
              <input
                type="email"
                id="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="Enter your email"
                required
                className="auth-input-field"
              />
            </div>

            <div className="auth-input-wrapper">
              <span className="auth-input-label">Password</span>
              <input
                type="password"
                id="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Enter your password"
                required
                className="auth-input-field"
              />
            </div>


            {message && (
              <div className={`message ${message.includes('failed') || message.includes('Error') ? 'error' : 'success'}`}>
                {message}
              </div>
            )}

            <button type="submit" className="auth-button" disabled={loading}>
              {loading ? (isLogin ? 'Signing In...' : 'Creating Account...') : (isLogin ? 'Sign In' : 'Create Account')}
            </button>
          </form>

          <div className="auth-links">
            <p>
              {isLogin ? "Don't have an account? " : "Already have an account? "}
              <button type="button" onClick={toggleMode} className="link-button">
                {isLogin ? 'Create one' : 'Sign in'}
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

export default AuthPage;
