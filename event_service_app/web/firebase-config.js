// Import the functions you need from the SDKs you need
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
// TODO: Add SDKs for Firebase products that you want to use
// https://firebase.google.com/docs/web/setup#available-libraries

// Your web app's Firebase configuration
// For Firebase JS SDK v7.20.0 and later, measurementId is optional
const firebaseConfig = {
    apiKey: "AIzaSyC6vlE0vFylHnTcPieQ6-bUK9wQ7b5Bv7w",
    authDomain: "eventserviceapp-6ff7a.firebaseapp.com",
    projectId: "eventserviceapp-6ff7a",
    storageBucket: "eventserviceapp-6ff7a.firebasestorage.app",
    messagingSenderId: "248694754665",
    appId: "1:248694754665:web:4cfa9f25ea3f5a052881f8",
    measurementId: "G-0D8VEVQGC7"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);