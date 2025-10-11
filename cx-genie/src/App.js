import React, { useState, useEffect } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from './firebase';
import Login from './Login';
import './App.css';

function App() {
  const [user, setUser] = useState(null);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
    });
    return () => unsubscribe();
  }, []);

  return (
    <div className="App">
      {user ? (
        <header className="App-header">
          <h1>Welcome, {user.email}!</h1>
          <p>You are logged in to CX Genie.</p>
        </header>
      ) : (
        <Login />
      )}
    </div>
  );
}

export default App;
