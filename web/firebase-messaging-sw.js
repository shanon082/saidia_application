importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDSKgnpFu2kFdY206XP30Fg_owCEgW91P4',
  authDomain: 'saidia-app-e28dd.firebaseapp.com',
  projectId: 'saidia-app-e28dd',
  storageBucket: 'saidia-app-e28dd.firebasestorage.app',
  messagingSenderId: '157645569808',
  appId: '1:157645569808:web:56d956e54056579d4c2f95',
  measurementId: 'G-2LY427JSWS'
});

const messaging = firebase.messaging();
