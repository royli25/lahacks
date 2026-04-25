import React, { useState, useEffect } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';

function Dashboard({ user, onSignOut }) {
  const navigate = useNavigate();
  const location = useLocation();
  const { patientName, selectedDoctor, phoneNumber } = location.state || {};
  const [expandedCheckupId, setExpandedCheckupId] = useState(null);

  // Filler defaults
  const fallbackPatientName = 'Emaan';
  const fallbackPhoneNumber = '8923804239';
  const fallbackDoctorNameBanner = 'Dr. Dexter Sins';
  const fallbackDoctorNamePlain = 'Dr. Dexter Sins';

  const displayPatientName = patientName || fallbackPatientName;
  const displayPhoneNumber = phoneNumber || fallbackPhoneNumber;
  const displayDoctorBanner = (selectedDoctor?.name) || fallbackDoctorNameBanner;
  const displayDoctorPlain = (selectedDoctor?.name) || fallbackDoctorNamePlain;

  // Mock checkup data with transcripts
  const checkups = [
    {
      id: 1,
      date: 'October 17, 2025',
      time: '1:46 PM',
      doctor: 'Dr. Dexter Sins',
      type: 'Annual Physical',
      status: 'complete',
      transcript: [
        { speaker: 'doctor', text: 'Hello Emaan, I’m Dr. Dexter. It’s good to see you again. Last time you mentioned you were having some back pain. Is that still occurring?', time: '1:46:09 PM' },
        { speaker: 'patient', text: 'Yeah, it’s getting worse, actually.', time: '1:46:21 PM' },
        { speaker: 'doctor', text: 'I’m sorry to hear that. Have you done anything recently that might’ve aggravated it?', time: '1:46:21 PM' },
        { speaker: 'patient', text: 'Well, it’s funny you say that. I’ve been up all night, slouched over with horrible posture, working on my hackathon project.', time: '1:46:35 PM' },
        { speaker: 'doctor', text: 'That makes sense. I would recommend keeping your screen at eye level and taking short breaks to stand and stretch. Does this plan make sense to you?', time: '1:46:36 PM' },
        { speaker: 'patient', text: 'This makes perfect sense. Thank you, Doctor.', time: '1:46:48 PM' },
        { speaker: 'doctor', text: 'You’re very welcome, Emaan! I’m glad to hear that. If you have any other questions or concerns, feel free to reach out.', time: '1:47 PM' }
      ],
      summary: 'Emaan reports worsening back pain since the last consultation. The aggravation appears linked to prolonged sitting with poor posture while working overnight on a hackathon project. Dr. Dexter suggests he keeps the computer screen at eye level and takes frequent short breaks to stand and stretch. Emaan agrees to follow recommendations.',
      prescriptions: ['Continue daily multivitamin'],
      nextSteps: ['Schedule follow-up in 6 months', 'Continue exercise routine']
    },
    {
      id: 2,
      // Move this empty checkup to the far right by making it a future checkup
      date: 'January 10, 2026',
      time: '10:00 AM',
      doctor: displayDoctorBanner,
      type: 'Follow-up Checkup',
      status: 'scheduled',
      transcript: null,
      summary: null,
      prescriptions: null,
      nextSteps: null
    },
    {
      id: 3,
      date: 'August 10, 2024',
      time: '3:15 PM',
      doctor: 'Dr. Dexter Sins',
      type: 'Routine Checkup',
      status: 'complete',
      transcript: [
        { speaker: 'doctor', text: 'Hello! I see you\'re here for a routine checkup.', time: '3:15 PM' },
        { speaker: 'patient', text: 'Yes, I wanted to discuss my recent fatigue.', time: '3:16 PM' },
        { speaker: 'doctor', text: 'Let\'s run some blood work to check your iron and vitamin D levels.', time: '3:17 PM' },
        { speaker: 'patient', text: 'Sounds good.', time: '3:17 PM' },
        { speaker: 'doctor', text: 'Your results show slightly low vitamin D. I\'ll prescribe a supplement.', time: '3:25 PM' },
        { speaker: 'patient', text: 'Will that help with the fatigue?', time: '3:26 PM' },
        { speaker: 'doctor', text: 'Yes, you should notice improvement in 2-3 weeks. Also try to get 15 minutes of sunlight daily.', time: '3:27 PM' }
      ],
      summary: 'Patient reported fatigue. Blood work revealed low vitamin D levels. Prescribed supplement.',
      prescriptions: ['Vitamin D3 2000 IU daily'],
      nextSteps: ['Follow-up in 4 weeks', 'Get 15 minutes sunlight daily', 'Retest vitamin D levels']
    }
  ];

  // Derive status from date/time and sort by most recent first
  const toDate = (c) => new Date(`${c.date} ${c.time}`);
  const now = new Date();
  const augmented = checkups.map((c) => ({ ...c, status: toDate(c) < now ? 'complete' : 'scheduled', _sortDate: toDate(c) }));
  const past = augmented.filter((c) => c._sortDate < now).sort((a, b) => b._sortDate - a._sortDate); // newest past first
  const future = augmented.filter((c) => c._sortDate >= now).sort((a, b) => a._sortDate - b._sortDate); // earliest future first
  const normalizedCheckups = past.concat(future); // place upcoming to the far right

  const handleCheckupClick = (checkupId) => {
    // Always show the details card for the clicked checkup
    setExpandedCheckupId(checkupId);
  };

  // Transcript collapse state for the currently expanded checkup
  const [isTranscriptOpen, setIsTranscriptOpen] = useState(true);
  useEffect(() => {
    // Reset transcript open when switching checkups
    setIsTranscriptOpen(true);
  }, [expandedCheckupId]);

  // Build a simple paragraph summary from a transcript when none is provided
  const buildSummaryFromTranscript = (transcript) => {
    if (!transcript || transcript.length === 0) return 'No summary available.';
    // Prefer doctor statements, then patient, trimmed to a readable length
    const doctorText = transcript.filter(m => m.speaker === 'doctor').map(m => m.text).join(' ');
    const patientText = transcript.filter(m => m.speaker === 'patient').map(m => m.text).join(' ');
    const combined = `${doctorText} ${patientText}`.replace(/\s+/g, ' ').trim();
    return combined.length > 350 ? combined.slice(0, 350).trim() + '…' : combined;
  };

  return (
  <div className="App dashboard-page">
    <div className="header-container">
      <img src="/a.svg" alt="Amiya Health Logo" className="logo" />
      <h2 className="brand-name">amiya health</h2>
      {user ? (
        <button className="signup-button" onClick={onSignOut}>
          sign out
        </button>
      ) : (
        <button className="signup-button" onClick={() => navigate('/auth')}>
          sign up
        </button>
      )}
    </div>

    <div className="dashboard-stack">
      <div className="dashboard-header">
        <h1>Dashboard</h1>
      </div>
      <div className="success-notification">
        <div className="success-notification-inner">
          ✓ Successfully set-up check-up appointment for {displayPatientName} ({displayPhoneNumber}) with {displayDoctorBanner}
        </div>
      </div>

      <div className="dashboard-content">
        <div className="patient-info">
          <div className="patient-summary">
            <p className="patient-name">{displayPatientName}</p>
            <p className="patient-phone">{displayPhoneNumber}</p>
            <p className="patient-doctor">Doctor {displayDoctorPlain}</p>
          </div>
        </div>

        <div className="status-separator" />

        <div className="checkup-boxes">
          {normalizedCheckups.map((checkup) => (
            <div 
              key={checkup.id}
              className={`checkup-box clickable ${expandedCheckupId === checkup.id ? 'expanded' : ''}`}
              onClick={() => handleCheckupClick(checkup.id)}
              style={{ cursor: 'pointer' }}
            >
              <div className="checkup-header">{checkup.status === 'complete' ? 'past checkup' : 'upcoming'}</div>
              <div className="checkup-meta">
                <span className="checkup-date">{checkup.date.split(',')[0]}</span>
                <span className="checkup-doctor">{checkup.doctor}</span>
              </div>
              <span className={`checkup-status ${checkup.status === 'complete' ? 'complete' : 'incomplete'}`}>
                {checkup.status === 'complete' ? 'complete' : 'scheduled'}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* MOVED INSIDE dashboard-stack */}
      {expandedCheckupId && normalizedCheckups.find(c => c.id === expandedCheckupId) && (
        <div className="checkup-details-fullwidth">
          {(() => {
            const checkup = normalizedCheckups.find(c => c.id === expandedCheckupId);
            return (
              <>
                <div className="details-header">
                  <h3>{checkup.type}</h3>
                </div>

                <div className="details-grid">
                  <div className="details-section session-stats-section">
                    <h4>Session Statistics</h4>
                    {(() => {
                      const parseTimeToMinutes = (t) => {
                        if (!t) return null;
                        const [time, ampm] = t.split(' ');
                        const [hStr, mStr] = time.split(':');
                        let h = parseInt(hStr, 10);
                        const m = parseInt(mStr, 10);
                        if (ampm === 'PM' && h !== 12) h += 12;
                        if (ampm === 'AM' && h === 12) h = 0;
                        return h * 60 + m;
                      };
                      const duration = (() => {
                        if (!checkup.transcript || checkup.transcript.length < 2) return '—';
                        const start = parseTimeToMinutes(checkup.transcript[0].time);
                        const end = parseTimeToMinutes(checkup.transcript[checkup.transcript.length - 1].time);
                        if (start == null || end == null || end < start) return '—';
                        const minutes = end - start;
                        const h = Math.floor(minutes / 60);
                        const m = minutes % 60;
                        return h > 0 ? `${h}h ${m}m` : `${m}m`;
                      })();
                      return (
                        <div className="session-stats">
                          <div className="stat-row"><span className="stat-label">Call Date:</span><span className="stat-value">{checkup.date}</span></div>
                          <div className="stat-row"><span className="stat-label">Call Duration:</span><span className="stat-value">{duration}</span></div>
                          <div className="stat-row"><span className="stat-label">Status:</span><span className="stat-value">{checkup.status === 'complete' ? 'Complete' : 'Incomplete'}</span></div>
                        </div>
                      );
                    })()}
                  </div>

                  {/* Summary paragraph card */}
                  <div className="details-section transcript-section-full summary-section">
                    <div className="transcript-card">
                      <div className="transcript-header">Summary</div>
                      <div className="transcript-messages open">
                        <div className="transcript-message">
                          <p className="message-text">
                            {checkup.summary || buildSummaryFromTranscript(checkup.transcript)}
                          </p>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div className="details-section transcript-section-full">
                    <div className="transcript-card">
                      <div
                        className="transcript-header"
                        onClick={() => setIsTranscriptOpen((prev) => !prev)}
                      >
                        Conversation Transcript
                        <span className={`collapse-icon ${isTranscriptOpen ? 'open' : 'closed'}`}>
                          {isTranscriptOpen ? '▲' : '▼'}
                        </span>
                      </div>
                      <div className={`transcript-messages ${isTranscriptOpen ? 'open' : 'collapsed'}`}>
                      {checkup.transcript?.map((message, index) => (
                        <div key={index} className={`transcript-message ${message.speaker}`}>
                          <div className="message-header">
                            <span className="message-speaker">
                              {message.speaker === 'doctor' ? checkup.doctor : displayPatientName}
                            </span>
                            <span className="message-time">{message.time}</span>
                          </div>
                          <p className="message-text">{message.text}</p>
                        </div>
                      ))}
                      </div>
                    </div>
                  </div>

                  {/* Prescriptions section removed per requirements */}

                  {checkup.nextSteps && (
                    <div className="next-steps-aligned">
                      <div className="next-steps-card">
                        <div className="next-steps-header">Next Steps</div>
                        <div className="next-steps-body">
                          <ul className="next-steps-list">
                            {checkup.nextSteps.map((step, index) => (
                              <li key={index}>✓ {step}</li>
                            ))}
                          </ul>
                        </div>
                      </div>
                    </div>
                  )}

                </div>
              </>
            );
          })()}
        </div>
      )}

    </div> {/* End dashboard-stack */}
  </div>
);

}

export default Dashboard;
