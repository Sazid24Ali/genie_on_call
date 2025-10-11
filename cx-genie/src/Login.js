import React, { useState } from "react";
import { signInWithCustomToken } from "firebase/auth";
import { httpsCallable } from "firebase/functions";
import { auth, functions } from "./firebase";

function Login() {
  const [cxId, setCxId] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  const handleSignIn = async (e) => {
    e.preventDefault();
    try {
      const cxLogin = httpsCallable(functions, "cxLogin");
      const result = await cxLogin({ cxId, password });
      const customToken = result.data.customToken;
      await signInWithCustomToken(auth, customToken);
    } catch (error) {
      setError(error.message);
    }
  };

  return (
    <div>
      <h2>CX Login</h2>
      <form onSubmit={handleSignIn}>
        <input
          type="text"
          placeholder="CX ID"
          value={cxId}
          onChange={(e) => setCxId(e.target.value)}
          required
        />
        <input
          type="password"
          placeholder="Password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
        />
        <button type="submit">Sign In</button>
      </form>
      {error && <p>{error}</p>}
    </div>
  );
}

export default Login;
