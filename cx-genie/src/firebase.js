import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

const firebaseConfig = {
  apiKey: "AIzaSyD...",
  authDomain: "genie-on-call.firebaseapp.com",
  projectId: "genie-on-call",
  storageBucket: "genie-on-call.appspot.com",
  messagingSenderId: "123456789",
  appId: "1:123456789:web:abcdef"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);

export default app;
