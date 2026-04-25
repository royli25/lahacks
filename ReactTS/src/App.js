import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, useNavigate, useLocation, Link } from 'react-router-dom';
import { supabase } from './supabase';
import AuthPage from './AuthPage';
import Dashboard from './Dashboard';
import './App.css';

function Breadcrumb({ currentStep, patientName, selectedDoctor, phoneNumber }) {
  const navigate = useNavigate();

  const steps = [
    { id: 'home', label: 'Patient Info', path: '/' },
    { id: 'doctor', label: 'Select Doctor', path: '/select-doctor' },
    { id: 'phone', label: 'Phone Number', path: '/enter-phone' }
  ];

  const handleStepClick = (step) => {
    if (step.id === 'home') {
      navigate('/', { state: { patientName, selectedDoctor, phoneNumber } });
    } else if (step.id === 'doctor') {
      if (patientName) {
        navigate('/select-doctor', { state: { patientName, selectedDoctor, phoneNumber } });
      } else {
        // If no patient name, go to home first
        navigate('/');
      }
    } else if (step.id === 'phone') {
      if (patientName && selectedDoctor) {
        navigate('/enter-phone', { state: { patientName, selectedDoctor, phoneNumber } });
      } else if (patientName) {
        // If no doctor selected, go to doctor selection
        navigate('/select-doctor', { state: { patientName, selectedDoctor, phoneNumber } });
      } else {
        // If no patient name, go to home first
        navigate('/');
      }
    }
  };

  return (
    <nav className="breadcrumb">
      {steps.map((step, index) => (
        <div key={step.id} className="breadcrumb-item">
          <button
            className={`breadcrumb-step ${currentStep === step.id ? 'active' : ''} clickable`}
            onClick={() => handleStepClick(step)}
          >
            {step.label}
          </button>
          {index < steps.length - 1 && <span className="breadcrumb-separator"></span>}
        </div>
      ))}
    </nav>
  );
}

function HomePage({ user, onSignup, onSignOut }) {
  const navigate = useNavigate();
  const location = useLocation();
  const [patientName, setPatientName] = useState(location.state?.patientName || '');

  const handleCreateCheckup = (e) => {
    e.preventDefault();
    if (patientName.trim()) {
      navigate('/select-doctor', { state: { patientName } });
    } else {
      alert('Please enter a patient name');
    }
  };

  return (
    <div className="App">
      <div className="header-container">
        <img src="/a.svg" alt="Amiya Health Logo" className="logo" />
        <h2 className="brand-name">amiya health</h2>
        {user ? (
          <button className="signup-button" onClick={onSignOut}>
            sign out
          </button>
        ) : (
          <Link to="/auth" className="signup-button" style={{ textDecoration: 'none' }}>
            sign up
          </Link>
        )}
      </div>
      <h1>Making Elders Health Checkups<br />Affordable and Accessible</h1>
      <p>We Use AI Reasoning and Generative Video to Augment Your Loved Ones' Health</p>
      
      <div className="checkup-section">
        <div className="checkup-form">
          <div className="form-content">
            <span className="form-text">Start checkup for</span>
            <input
              type="text"
              value={patientName}
              onChange={(e) => setPatientName(e.target.value)}
              placeholder="Enter patient name"
              className="form-input"
              onKeyPress={(e) => {
                if (e.key === 'Enter') {
                  handleCreateCheckup(e);
                }
              }}
            />
          </div>
          <button className="send-button" onClick={handleCreateCheckup}>
            <span className="send-icon">→</span>
          </button>
        </div>
      </div>
    </div>
  );
}

function DoctorSelectionPage({ user, onSignup, onSignOut }) {
  const navigate = useNavigate();
  const location = useLocation();
  const patientName = location.state?.patientName || 'Patient';
  const [selectedDoctor, setSelectedDoctor] = useState(location.state?.selectedDoctor || null);

  const doctors = [
    { id: 1, name: 'Dr. Carol Lee', specialty: 'General Medicine', avatar: '/Screenshot 2025-10-17 at 8.03.39 AM.png' },
    { id: 3, name: 'Dr. Dexter Sins', specialty: 'Pediatrics', video: '/Screen Recording 2025-10-17 at 8.01.56 AM.mov' },
    { id: 2, name: 'Dr. Karen Roberts', specialty: 'Cardiology', avatar: '/Screenshot 2025-10-17 at 8.04.27 AM.png' }
  ];

  const handleDoctorSelect = (doctor) => {
    setSelectedDoctor(doctor);
  };

  const handleNext = () => {
    if (selectedDoctor) {
      navigate('/enter-phone', { state: { patientName, selectedDoctor } });
    }
  };

  return (
    <div className="App">
      <Breadcrumb currentStep="doctor" patientName={patientName} selectedDoctor={selectedDoctor} />
      <div className="header-container">
        <img src="/a.svg" alt="Amiya Health Logo" className="logo" />
        <h2 className="brand-name">amiya health</h2>
        {user ? (
          <button className="signup-button" onClick={onSignOut}>
            sign out
          </button>
        ) : (
          <Link to="/auth" className="signup-button" style={{ textDecoration: 'none' }}>
            sign up
          </Link>
        )}
      </div>
      <p className="page-subtitle">Choose a doctor for {patientName}'s checkup</p>
      
      <div className="doctors-grid">
        {doctors.map((doctor) => (
          <div 
            key={doctor.id} 
            className={`doctor-card ${selectedDoctor?.id === doctor.id ? 'selected' : ''}`} 
            onClick={() => handleDoctorSelect(doctor)}
          >
            <div className="doctor-media-wrapper">
              {doctor.video ? (
                <video
                  className="doctor-media"
                  src={doctor.video}
                  muted
                  loop
                  playsInline
                  preload="metadata"
                  onMouseEnter={(e) => {
                    e.currentTarget.play();
                  }}
                  onMouseLeave={(e) => {
                    e.currentTarget.pause();
                    e.currentTarget.currentTime = 0;
                  }}
                  aria-label={`${doctor.name} preview`}
                />
              ) : doctor.avatar ? (
                <img src={doctor.avatar} alt={`${doctor.name} portrait`} className="doctor-media" />
              ) : null}

              <div className="doctor-overlay">
                <div className="doctor-name">{doctor.name}</div>
              </div>
            </div>
          </div>
        ))}
      </div>
      
      <button 
        className={`next-button ${selectedDoctor ? 'active' : ''}`} 
        onClick={handleNext}
        disabled={!selectedDoctor}
      >
        Next →
      </button>
    </div>
  );
}

function PhoneEntryPage({ user, onSignup, onSignOut }) {
  const navigate = useNavigate();
  const location = useLocation();
  const { patientName, selectedDoctor } = location.state || {};
  const [phoneNumber, setPhoneNumber] = useState(location.state?.phoneNumber || '');
  const [showLoginPopup, setShowLoginPopup] = useState(false);
  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [loginLoading, setLoginLoading] = useState(false);
  const [loginMessage, setLoginMessage] = useState('');

  const formatPhoneNumber = (value) => {
    // Remove all non-numeric characters
    const phoneNumber = value.replace(/\D/g, '');
    
    // Format as (XXX) XXX-XXXX
    if (phoneNumber.length === 0) return '';
    if (phoneNumber.length <= 3) return `(${phoneNumber}`;
    if (phoneNumber.length <= 6) return `(${phoneNumber.slice(0, 3)}) ${phoneNumber.slice(3)}`;
    return `(${phoneNumber.slice(0, 3)}) ${phoneNumber.slice(3, 6)}-${phoneNumber.slice(6, 10)}`;
  };

  const handlePhoneChange = (e) => {
    const formatted = formatPhoneNumber(e.target.value);
    setPhoneNumber(formatted);
  };

  const handleSubmit = async () => {
    if (phoneNumber.trim()) {
      // Check if user is logged in
      if (!user) {
        setShowLoginPopup(true);
        return;
      }
      
      // Navigate to dashboard after successful phone number entry
      navigate('/dashboard', { state: { patientName, selectedDoctor, phoneNumber } });
    } else {
      alert('Please enter a phone number');
    }
  };

  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    setLoginLoading(true);
    setLoginMessage('');

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: loginEmail,
        password: loginPassword,
      });
      
      if (error) {
        setLoginMessage('Login failed: ' + error.message);
      } else {
        setLoginMessage('Login successful!');
        setShowLoginPopup(false);
        setLoginEmail('');
        setLoginPassword('');
        // Automatically proceed with phone submission after successful login
        setTimeout(() => {
          navigate('/dashboard', { state: { patientName, selectedDoctor, phoneNumber } });
        }, 500);
      }
    } catch (error) {
      setLoginMessage('Error: ' + error.message);
    } finally {
      setLoginLoading(false);
    }
  };

  const handleBack = () => {
    navigate('/select-doctor', { state: { patientName, selectedDoctor, phoneNumber } });
  };

  return (
    <div className="App">
      <Breadcrumb currentStep="phone" patientName={patientName} selectedDoctor={selectedDoctor} phoneNumber={phoneNumber} />
      <div className="header-container">
        <img src="/a.svg" alt="Amiya Health Logo" className="logo" />
        <h2 className="brand-name">amiya health</h2>
        {user ? (
          <button className="signup-button" onClick={onSignOut}>
            sign out
          </button>
        ) : (
          <Link to="/auth" className="signup-button" style={{ textDecoration: 'none' }}>
            sign up
          </Link>
        )}
      </div>
      <p className="page-subtitle phone-subtitle">Please provide the phone number for {patientName}</p>
      
      <div className="phone-form">
        <div className="form-content">
          <span className="form-text">Phone number</span>
          <input
            type="tel"
            value={phoneNumber}
            onChange={handlePhoneChange}
            placeholder="(XXX) XXX-XXXX"
            className="form-input"
            maxLength="14"
            onKeyPress={(e) => {
              if (e.key === 'Enter') {
                handleSubmit();
              }
            }}
          />
        </div>
        <button 
          className={`send-button ${phoneNumber.length === 14 ? 'active' : 'disabled'}`}
          onClick={handleSubmit}
          disabled={phoneNumber.length !== 14}
        >
          <span className="send-icon">→</span>
        </button>
      </div>

      {/* Login Popup */}
      {showLoginPopup && (
        <div className="login-popup-overlay">
          <div className="login-popup-card">
            <div className="login-popup-header">
              <h3>Sign In Required</h3>
              <button 
                className="close-popup" 
                onClick={() => setShowLoginPopup(false)}
              >
                ×
              </button>
            </div>
            <p style={{ textAlign: 'left', marginBottom: '2rem' }}>Please sign in to continue with your checkup.</p>
            
            <form onSubmit={handleLoginSubmit}>
              <div className="auth-input-wrapper">
                <span className="auth-input-label">Email</span>
                <input
                  type="email"
                  id="popup-email"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  placeholder="Enter your email"
                  required
                  className="auth-input-field"
                />
              </div>

              <div className="auth-input-wrapper">
                <span className="auth-input-label">Password</span>
                <input
                  type="password"
                  id="popup-password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  placeholder="Enter your password"
                  required
                  className="auth-input-field"
                />
              </div>

              {loginMessage && (
                <div className={`message ${loginMessage.includes('failed') || loginMessage.includes('Error') ? 'error' : 'success'}`}>
                  {loginMessage}
                </div>
              )}

              <button type="submit" className="auth-button" disabled={loginLoading}>
                {loginLoading ? 'Signing In...' : 'Sign In'}
              </button>
            </form>

            <div className="auth-links">
              <p>Don't have an account? <Link to="/auth">Create one</Link></p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function App() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    // Get initial session
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
    });

    // Listen for auth changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
    });

    return () => subscription.unsubscribe();
  }, []);

  // Navigate to signup page
  const handleSignup = () => {
    window.location.href = '/signup';
  };

  // Sign out function
  const handleSignOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <Router>
      <Routes>
        <Route path="/" element={<HomePage user={user} onSignup={handleSignup} onSignOut={handleSignOut} />} />
        <Route path="/select-doctor" element={<DoctorSelectionPage user={user} onSignup={handleSignup} onSignOut={handleSignOut} />} />
        <Route path="/enter-phone" element={<PhoneEntryPage user={user} onSignup={handleSignup} onSignOut={handleSignOut} />} />
        <Route path="/dashboard" element={<Dashboard user={user} onSignOut={handleSignOut} />} />
        <Route path="/auth" element={<AuthPage />} />
      </Routes>
    </Router>
  );
}

export default App;
