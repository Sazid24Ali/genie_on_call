import { initializeApp } from "https://www.gstatic.com/firebasejs/9.22.0/firebase-app.js";
import {
  getFirestore,
  collection,
  getDocs,
  doc,
  getDoc,
  setDoc,
  updateDoc,
  onSnapshot,
  addDoc,
  deleteDoc,
  query,
  orderBy,
  limit,
  where,
  serverTimestamp,
} from "https://www.gstatic.com/firebasejs/9.22.0/firebase-firestore.js";
import {
  getStorage,
  ref,
  uploadBytes,
  getDownloadURL,
} from "https://www.gstatic.com/firebasejs/9.22.0/firebase-storage.js";

// Your web app's Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBlotfOVqLY-HXhLUrxmnX22IGm-7ycXPE",
  authDomain: "genie-on-call-769a1.firebaseapp.com",
  projectId: "genie-on-call-769a1",
  storageBucket: "genie-on-call-769a1.firebasestorage.app",
  messagingSenderId: "341283748050",
  appId: "1:341283748050:web:27f16d29dbf79a6d47d50b",
  measurementId: "G-STDL7BSTJX",
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);
const storage = getStorage(app);

let currentUser = null;
let agents = [];
let servicesList = [];
let bookings = [];
let chats = [];
let chatRequests = [];
let bookingsUnsubscribe = null;
let chatRequestsUnsubscribe = null;
let chatsUnsubscribe = null;
let currentChatFilter = "active"; // "all", "closed", or "active"
let currentChatContainer = "chats-general"; // "chats-general"

const loginContainer = document.getElementById("login-container");
const dashboardContainer = document.getElementById("dashboard-container");
const loginForm = document.getElementById("login-form");
const logoutBtn = document.getElementById("logout-btn");
const bookingsGrid = document.getElementById("bookings-grid");
const serviceFilter = document.getElementById("service-filter");
const statusFilter = document.getElementById("status-filter");
const agentFilter = document.getElementById("agent-filter");
const chatRequestsList = document.getElementById("chat-requests-list");
const agentsList = document.getElementById("agents-list");
const advancedFiltersToggle = document.getElementById(
  "advanced-filters-toggle"
);
const advancedFilters = document.getElementById("advanced-filters");
const quickDateFilter = document.getElementById("quick-date-filter");
const dateRangePicker = document.getElementById("date-range-picker");
const clearFiltersBtn = document.getElementById("clear-filters-btn");
const slotDate = document.getElementById("slot-date");
const currentSlots = document.getElementById("current-slots");
let selectedAgentServices = [];
let dateRangePickerInstance = null;

// Check if user is logged in on load
const storedUser = localStorage.getItem("cxUser");
if (storedUser) {
  currentUser = JSON.parse(storedUser);
  showDashboard();
  loadData();
} else {
  showLogin();
}

loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const cxId = document.getElementById("cx-id").value;
  const password = document.getElementById("password").value;
  try {
    const cxLoginSnapshot = await getDocs(collection(db, "cx_logins"));
    const cxUsers = cxLoginSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    const user = cxUsers.find(
      (u) => (u.cxId === cxId || u.cx_id === cxId) && u.password === password
    );
    if (user) {
      // normalize to camelCase for in-memory usage
      currentUser = { cxId: user.cxId || user.cx_id };
      localStorage.setItem("cxUser", JSON.stringify(currentUser));
      showDashboard();
      loadData();
      console.log("Logged in as:", currentUser.cxId);
    } else {
      document.getElementById("login-error").textContent =
        "Invalid CX ID or password";
    }
  } catch (error) {
    document.getElementById("login-error").textContent = error.message;
  }
});

logoutBtn.addEventListener("click", () => {
  currentUser = null;
  localStorage.removeItem("cxUser");
  if (bookingsUnsubscribe) bookingsUnsubscribe();
  if (chatRequestsUnsubscribe) chatRequestsUnsubscribe();
  if (chatsUnsubscribe) chatsUnsubscribe();
  showLogin();
});

function showLogin() {
  loginContainer.classList.remove("hidden");
  dashboardContainer.classList.add("hidden");
}

function showDashboard() {
  loginContainer.classList.add("hidden");
  dashboardContainer.classList.remove("hidden");
  // Show loading in bookings grid
  bookingsGrid.innerHTML = `
    <div class="col-12 text-center">
      <div class="spinner-border text-primary" role="status">
        <span class="visually-hidden">Loading...</span>
      </div>
      <p class="mt-2">Loading bookings...</p>
    </div>
  `;
}

async function loadData() {
  await loadAgents();
  await loadServices();
  initializeDateFilters();
  initializeSlots();
  setupBookingsListener();
  setupChatRequestsListener();
  setupChatsListener();
  setupChatFilters();
  populateAgentServiceFilter();
  displayAgents();
}

async function loadServices() {
  const servicesSnapshot = await getDocs(collection(db, "services"));
  servicesList = servicesSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
  populateServiceFilter();
}

async function loadAgents() {
  const agentsSnapshot = await getDocs(collection(db, "agents"));
  agents = agentsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  populateAgentFilter();
}

function setupBookingsListener() {
  if (bookingsUnsubscribe) bookingsUnsubscribe();
  const bookingsQuery = query(
    collection(db, "bookings"),
    orderBy("createdAt", "desc")
  );
  bookingsUnsubscribe = onSnapshot(bookingsQuery, (snapshot) => {
    bookings = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    displayBookings(bookings);
  });
}

function populateServiceFilter() {
  serviceFilter.innerHTML = '<option value="">All Services</option>';
  servicesList.forEach((service) => {
    const option = document.createElement("option");
    option.value = service.name;
    option.textContent = service.name;
    serviceFilter.appendChild(option);
  });
}

function populateAgentFilter() {
  agentFilter.innerHTML = '<option value="">All Agents</option>';
  agents.forEach((agent) => {
    const option = document.createElement("option");
    option.value = agent.id;
    option.textContent = agent.name;
    agentFilter.appendChild(option);
  });
}

function getStatusBadgeClass(status) {
  switch (status) {
    case "closed":
      return "danger";
    case "Pending":
      return "warning";
    case "Accepted":
      return "info";
    case "Finished":
      return "success";
    case "Cancelled":
      return "danger";
    default:
      return "secondary";
  }
}

function displayBookings(allBookings) {
  bookingsGrid.innerHTML = "";
  const filteredBookings = filterBookings(allBookings);

  filteredBookings.forEach((booking) => {
    const col = document.createElement("div");
    col.className = "col-md-6 col-lg-4";
    const agentName =
      agents.find((a) => a.id === booking.agentId)?.name || "Unassigned";
    const serviceName =
      servicesList.find((s) => s.id === booking.serviceId)?.name ||
      booking.service ||
      booking.serviceName;
    const imagesLink =
      booking.images && booking.images.length > 0
        ? `<br><a href="${booking.images[0]}" target="_blank" class="text-decoration-none">View Images (${booking.images.length})</a>`
        : "";
    const recordingLink = booking.recording
      ? `<br><a href="${booking.recording}" target="_blank" class="text-decoration-none">View Recording</a>`
      : "";
    const bookingDate = booking.bookingDate
      ? new Date(booking.bookingDate.toDate()).toLocaleDateString()
      : "N/A";
    const bookingTime = booking.bookingTime || "N/A";
    const isAssigned = booking.agentId;
    col.innerHTML = `
      <div class="card h-100 shadow-sm">
        <div class="card-header bg-primary text-white">
          <h6 class="mb-0">${serviceName}</h6>
        </div>
        <div class="card-body">
          <p><strong>Status:</strong> <span class="badge bg-${getStatusBadgeClass(
            booking.status
          )}">${booking.status}</span></p>
          <p><strong>User:</strong> ${booking.userName || booking.userId}</p>
          <p><strong>Phone:</strong> ${booking.userPhone}</p>
          <p><strong>Address:</strong> ${booking.userAddress}</p>
          <p><strong>Date/Time:</strong> ${bookingDate} at ${bookingTime}</p>
          <p><strong>Cost:</strong> ₹${booking.cost}</p>
          <p><strong>Description:</strong> ${booking.description || "-"}</p>
          <p><strong>Agent:</strong> ${agentName}</p>
          <div class="mt-2">
            <select class="form-select form-select-sm" id="agent-select-${
              booking.id
            }" onchange="updateAgentSelection('${booking.id}', this.value)">
              <option value="">Assign Agent</option>
              ${agents
                .map(
                  (agent) =>
                    `<option value="${agent.id}" ${
                      booking.agentId === agent.id ? "selected" : ""
                    }>${agent.name}</option>`
                )
                .join("")}
            </select>
            <button class="btn btn-success btn-sm mt-1" id="save-btn-${
              booking.id
            }" onclick="saveAgentAssignment('${booking.id}')" ${
      !isAssigned ? "disabled" : ""
    }>Save</button>
            <button class="btn btn-info btn-sm mt-1 ms-1" onclick="openBookingChat('${
              booking.id
            }', '${
      booking.userId || booking.userName
    }')">Chat with User</button>
            <button class="btn btn-danger btn-sm mt-1 ms-1" onclick="cancelBooking('${
              booking.id
            }')">Cancel Booking</button>
          </div>
        </div>
        <div class="card-footer text-muted small">
          Created: ${
            booking.createdAt
              ? new Date(booking.createdAt.toDate()).toLocaleDateString()
              : "N/A"
          }
          ${imagesLink}
          ${recordingLink}
        </div>
      </div>
    `;
    bookingsGrid.appendChild(col);
  });
}

serviceFilter.addEventListener("change", () => displayBookings(bookings));
statusFilter.addEventListener("change", () => displayBookings(bookings));

let pendingAssignments = {};

window.updateAgentSelection = (bookingId, agentId) => {
  const saveBtn = document.getElementById(`save-btn-${bookingId}`);
  if (agentId) {
    pendingAssignments[bookingId] = agentId;
    saveBtn.disabled = false;
  } else {
    delete pendingAssignments[bookingId];
    saveBtn.disabled = true;
  }
};

window.saveAgentAssignment = async (bookingId) => {
  const agentId = pendingAssignments[bookingId];
  if (!agentId) return;

  try {
    await updateDoc(doc(db, "bookings", bookingId), {
      agentId,
      status: "Accepted",
      acceptedAt: new Date(),
    });
    delete pendingAssignments[bookingId];
    const saveBtn = document.getElementById(`save-btn-${bookingId}`);
    saveBtn.disabled = true;
    console.log("Agent assigned and status set to Accepted");
  } catch (error) {
    console.error("Error assigning agent:", error);
  }
};

window.assignAgent = async (bookingId, agentId) => {
  // Legacy function, kept for compatibility
  if (agentId) {
    await saveAgentAssignment(bookingId);
  }
};

window.cancelBooking = async (bookingId) => {
  if (!confirm("Are you sure you want to cancel this booking?")) return;

  try {
    await updateDoc(doc(db, "bookings", bookingId), {
      status: "Cancelled",
      cancelledAt: new Date(),
    });
    console.log("Booking cancelled successfully");
  } catch (error) {
    console.error("Error cancelling booking:", error);
    alert("Error cancelling booking: " + error.message);
  }
};

function setupChatRequestsListener() {
  if (chatRequestsUnsubscribe) chatRequestsUnsubscribe();
  const chatRequestsQuery = query(
    collection(db, "chats"),
    where("status", "==", "requested"),
    orderBy("createdAt", "desc")
  );
  chatRequestsUnsubscribe = onSnapshot(chatRequestsQuery, (snapshot) => {
    chatRequests = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    displayChatRequests(chatRequests);
  });
}

async function acceptChat(chatId) {
  try {
    await updateDoc(doc(db, "chats", chatId), {
      status: "accepted",
      cxId: currentUser.cxId,
      acceptedAt: serverTimestamp(),
    });
    console.log("Chat accepted:", chatId);
  } catch (error) {
    console.error("Error accepting chat:", error);
    alert("Error accepting chat: " + error.message);
  }
}

window.acceptChat = acceptChat;
window.openChat = openChat;

async function closeChat(chatId) {
  if (!confirm("Are you sure you want to close this chat permanently?")) return;
  try {
    await updateDoc(doc(db, "chats", chatId), {
      status: "closed",
      closedAt: serverTimestamp(),
      closedBy: currentUser.cxId,
    });
    console.log("Chat closed:", chatId);
  } catch (error) {
    console.error("Error closing chat:", error);
    alert("Error closing chat: " + error.message);
  }
}

async function checkLastMessageSender(chat) {
  try {
    const messagesQuery = query(
      collection(db, "chats", chat.id, "messages"),
      orderBy("timestamp", "desc"),
      limit(1)
    );
    const messagesSnapshot = await getDocs(messagesQuery);
    if (!messagesSnapshot.empty) {
      const lastMessage = messagesSnapshot.docs[0].data();
      // Return true if the last message sender is not the current CX (i.e., it's from the user)
      return lastMessage.senderId !== currentUser.cxId;
    }
    return false; // No messages, so no unread
  } catch (error) {
    console.error("Error checking last message sender:", error);
    return false;
  }
}

async function displayChatItems(chats, containerId, showAccept = false) {
  const container = document.getElementById(containerId);
  if (!container) return;

  if (chats.length === 0) {
    container.innerHTML = '<div class="alert alert-info">No chats.</div>';
    return;
  }

  // Track existing items to update them instead of recreating
  const existingItems = {};
  container.querySelectorAll('[id^="chat-item-"]').forEach((el) => {
    existingItems[el.id] = el;
  });

  // Fetch user details for all unique userIds
  const userIds = [...new Set(chats.map((chat) => chat.userId))];
  const userDetails = {};
  for (const uid of userIds) {
    try {
      const userDoc = await getDoc(doc(db, "users", uid));
      if (userDoc.exists()) {
        userDetails[uid] = userDoc.data();
      }
    } catch (err) {
      console.error("Error fetching user:", uid, err);
      userDetails[uid] = {};
    }
  }

  // Remove duplicates based on chat.id
  const uniqueChats = chats.filter(
    (chat, index, self) => index === self.findIndex((c) => c.id === chat.id)
  );

  for (const chat of uniqueChats) {
    const itemId = `chat-item-${chat.id}`;
    let col = existingItems[itemId];
    const userInfo = userDetails[chat.userId] || {};
    const displayName = userInfo.name || chat.userName || "Guest User";
    const phone = userInfo.phone || "N/A";
    // Use cxUnreadCount for CX users
    const unreadCount = chat.cxUnreadCount;
    let hasUnread = unreadCount > 0;
    const isAccepted = chat.status === "accepted";
    const isClosed = chat.status === "closed";
    const statusBadge = isClosed ? "Closed" : isAccepted ? "Active" : "Pending";

    // Don't show unread for closed chats
    hasUnread = hasUnread && !isClosed;

    if (col) {
      // Update existing item
      const card = col.querySelector(".card");
      if (card) {
        // Update unread badge
        let existingBadge = card.querySelector(".badge.bg-danger");
        if (hasUnread) {
          if (!existingBadge) {
            existingBadge = document.createElement("span");
            existingBadge.className =
              "badge bg-danger rounded-pill position-absolute";
            existingBadge.style.fontWeight = "600";
            existingBadge.style.fontSize = "0.75rem";
            existingBadge.style.padding = "0.25em 0.5em";
            existingBadge.style.top = "10px";
            existingBadge.style.right = "10px";
            card.appendChild(existingBadge);
          }
          existingBadge.textContent = String(unreadCount);
        } else {
          if (existingBadge) existingBadge.remove();
        }
        // Update subtitle
        const subtitleDiv = card.querySelector("div div:nth-child(3)");
        if (subtitleDiv)
          subtitleDiv.textContent = chat.message || "Chat in progress";
        // Update status badge
        const statusBadgeEl = card.querySelector(
          ".badge.bg-success, .badge.bg-warning"
        );
        if (statusBadgeEl) {
          statusBadgeEl.className = isAccepted
            ? "badge bg-success rounded-pill"
            : "badge bg-warning rounded-pill";
          statusBadgeEl.textContent = statusBadge;
        }
      }
      delete existingItems[itemId]; // Mark as processed
    } else {
      // Create new item as tile
      col = document.createElement("div");
      col.className = "col-md-6 col-lg-4";
      col.id = itemId;

      const card = document.createElement("div");
      card.className = "card h-100 shadow-sm";
      card.style.position = "relative";

      const cardBody = document.createElement("div");
      cardBody.className = "card-body d-flex flex-column";

      const left = document.createElement("div");
      left.className = "flex-grow-1";
      left.innerHTML = `
        <div style="display:flex; align-items:center; gap:8px;">
          <div style="font-weight:700; font-size:1rem">${displayName}</div>
        </div>
        <div style="color:#6c757d; font-size:0.9rem">${phone}</div>
        <div style="margin-top:6px; color:#495057; font-size:0.95rem">${
          chat.message || "Chat in progress"
        }</div>
        <div style="margin-top:4px;"><small class="text-muted">${
          chat.createdAt
            ? new Date(chat.createdAt.toDate()).toLocaleString()
            : "N/A"
        }</small></div>
      `;

      // Position unread badge at the top right of the card
      if (hasUnread) {
        const unreadBadge = document.createElement("span");
        unreadBadge.className =
          "badge bg-danger rounded-pill position-absolute";
        unreadBadge.textContent = String(unreadCount);
        unreadBadge.style.fontWeight = "600";
        unreadBadge.style.fontSize = "0.75rem";
        unreadBadge.style.padding = "0.25em 0.5em";
        unreadBadge.style.top = "10px";
        unreadBadge.style.right = "10px";
        card.appendChild(unreadBadge);
      }

      const right = document.createElement("div");
      right.className =
        "d-flex align-items-center justify-content-between mt-2";

      const badge = document.createElement("span");
      // style the status badge according to acceptance status
      if (isAccepted) {
        badge.className = "badge bg-success rounded-pill";
        badge.textContent = "Active";
      } else {
        badge.className = "badge bg-warning rounded-pill";
        badge.textContent = "Pending";
      }

      const buttonsDiv = document.createElement("div");
      buttonsDiv.className = "d-flex gap-1";

      const openBtn = document.createElement("button");
      openBtn.className = "btn btn-sm btn-outline-primary";
      openBtn.textContent = "Open";
      openBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        // If container is minimized, maximize it first
        const chatTabsContent = document.getElementById("chat-tabs-content");
        if (chatTabsContent.style.display === "none") {
          const openChatsContainer = document.getElementById(
            "open-chats-container"
          );
          const minimizeBtn = document.getElementById("minimize-chat-btn");
          const maximizeBtn = document.getElementById("maximize-chat-btn");
          const closeBtn = document.getElementById("close-chat-container-btn");
          chatTabsContent.style.display = "block";
          openChatsContainer.style.height = "60vh";
          minimizeBtn.style.display = "inline-block";
          maximizeBtn.style.display = "none";
          closeBtn.disabled = false;
        }
        openChat(chat.id, chat.userId, userInfo);
      });

      const acceptBtn = document.createElement("button");
      acceptBtn.className = "btn btn-sm btn-success";
      acceptBtn.textContent = "Accept";
      acceptBtn.addEventListener("click", async (e) => {
        e.stopPropagation();
        try {
          await updateDoc(doc(db, "chats", chat.id), {
            status: "accepted",
            cxId: currentUser.cxId,
            acceptedAt: serverTimestamp(),
            cxUnreadCount: 0,
          });
          openChat(chat.id, chat.userId, userInfo);
        } catch (err) {
          console.error("Error accepting chat:", err);
          alert("Error accepting chat: " + (err.message || err));
        }
      });

      const closeBtn = document.createElement("button");
      closeBtn.className = "btn btn-sm btn-danger";
      closeBtn.textContent = "Close";
      closeBtn.addEventListener("click", async (e) => {
        e.stopPropagation();
        if (!confirm("Are you sure you want to close this chat permanently?"))
          return;
        try {
          await updateDoc(doc(db, "chats", chat.id), {
            status: "closed",
            closedAt: serverTimestamp(),
            closedBy: currentUser.cxId,
            cxUnreadCount: 0,
            userUnreadCount: 0,
          });
          console.log("Chat closed:", chat.id);
        } catch (error) {
          console.error("Error closing chat:", error);
          alert("Error closing chat: " + error.message);
        }
      });

      buttonsDiv.appendChild(openBtn);
      if (showAccept && !isAccepted) buttonsDiv.appendChild(acceptBtn);
      if (isAccepted) buttonsDiv.appendChild(closeBtn);
      right.appendChild(badge);
      right.appendChild(buttonsDiv);

      cardBody.appendChild(left);
      cardBody.appendChild(right);
      card.appendChild(cardBody);
      col.appendChild(card);
      container.appendChild(col);
    }
  }

  // Remove items no longer in the list
  Object.values(existingItems).forEach((el) => el.remove());
}

async function displayChats(chats) {
  displayChatItems(chats, "chats-tiles", false);
}

function setupChatsListener() {
  if (chatsUnsubscribe) chatsUnsubscribe();
  const chatsQuery = query(
    collection(db, "chats"),
    where("cxId", "==", currentUser.cxId),
    orderBy("createdAt", "desc")
  );
  chatsUnsubscribe = onSnapshot(chatsQuery, (snapshot) => {
    chats = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    categorizeAndDisplayChats(chats);
  });
}

function setupChatFilters() {
  document.getElementById("filter-all").addEventListener("click", () => {
    currentChatFilter = "all";
    setActiveFilter("filter-all");
    categorizeAndDisplayChats(chats);
  });
  document.getElementById("filter-active").addEventListener("click", () => {
    currentChatFilter = "active";
    setActiveFilter("filter-active");
    categorizeAndDisplayChats(chats);
  });
  document.getElementById("filter-closed").addEventListener("click", () => {
    currentChatFilter = "closed";
    setActiveFilter("filter-closed");
    categorizeAndDisplayChats(chats);
  });
  // Set default active filter to "active"
  setActiveFilter("filter-active");
}

function setActiveFilter(activeId) {
  ["filter-all", "filter-active", "filter-closed"].forEach((id) => {
    const btn = document.getElementById(id);
    if (id === activeId) {
      btn.classList.add("active");
    } else {
      btn.classList.remove("active");
    }
  });
}

function categorizeAndDisplayChats(allChats) {
  let filteredChats = allChats;
  if (currentChatFilter === "active") {
    filteredChats = allChats.filter((chat) => chat.status === "accepted");
  } else if (currentChatFilter === "closed") {
    filteredChats = allChats.filter((chat) => chat.status === "closed");
  }
  // For "all", no filter, but sort active first then closed

  if (currentChatFilter === "all") {
    filteredChats.sort((a, b) => {
      if (a.status === "accepted" && b.status !== "accepted") return -1;
      if (a.status !== "accepted" && b.status === "accepted") return 1;
      return 0;
    });
  }

  displayChatItems(filteredChats, currentChatContainer, false);
}

function populateAgentServiceFilter() {
  const serviceCheckboxes = document.getElementById("service-checkboxes");
  serviceCheckboxes.innerHTML = "";
  serviceCheckboxes.classList.add("p-2");
  servicesList.forEach((service) => {
    const li = document.createElement("li");
    li.innerHTML = `
      <div class="form-check form-check-inline">
        <input class="form-check-input" type="checkbox" value="${service.name}" id="service-${service.id}">
        <label class="form-check-label" for="service-${service.id}">
          ${service.name}
        </label>
      </div>
    `;
    serviceCheckboxes.appendChild(li);
    const checkbox = li.querySelector(`#service-${service.id}`);
    checkbox.addEventListener("change", () => {
      if (checkbox.checked) {
        selectedAgentServices.push(service.name);
      } else {
        selectedAgentServices = selectedAgentServices.filter(
          (s) => s !== service.name
        );
      }
      displayAgents();
    });
  });
}

function displayAgents() {
  agentsList.innerHTML = "";
  if (agents.length === 0) {
    agentsList.innerHTML =
      '<div class="alert alert-info">No agents available.</div>';
    return;
  }
  const filteredAgents =
    selectedAgentServices.length === 0
      ? agents
      : agents.filter((agent) => {
          if (!agent.services) return false;
          return selectedAgentServices.some((selectedService) =>
            agent.services.includes(selectedService)
          );
        });
  filteredAgents.forEach((agent) => {
    const col = document.createElement("div");
    col.className = "col-md-6 col-lg-4 mb-4";
    const servicesText = agent.services ? agent.services.join(", ") : "N/A";
    const joinedDate = agent.createdAt
      ? new Date(agent.createdAt.toDate()).toLocaleDateString()
      : "N/A";
    col.innerHTML = `
      <div class="card h-100 border-0 shadow-lg rounded-3 overflow-hidden">
        <div class="card-body p-4">
          <div class="d-flex align-items-center mb-3">
            <div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center me-3" style="width: 50px; height: 50px; font-size: 1.2rem; font-weight: bold;">
              ${agent.name.charAt(0).toUpperCase()}
            </div>
            <div>
              <h6 class="card-title mb-0 fw-bold">${agent.name}</h6>
              <small class="text-muted">${agent.phone || "No phone"}</small>
            </div>
          </div>
          <div class="row g-2 mb-3">
            <div class="col-6">
              <small class="text-muted d-block">Experience</small>
              <span class="fw-semibold">${agent.experience || "0"} years</span>
            </div>
            <div class="col-6">
              <small class="text-muted d-block">Joined</small>
              <span class="fw-semibold">${joinedDate}</span>
            </div>
          </div>
          <div class="mb-3">
            <small class="text-muted d-block">Services</small>
            <span class="badge bg-light text-dark me-1">${servicesText}</span>
          </div>
          <div class="d-flex justify-content-between align-items-center">
            <span class="badge bg-success rounded-pill px-3 py-2">Active</span>
            <small class="text-muted">${agent.id}</small>
          </div>
        </div>
      </div>
    `;
    agentsList.appendChild(col);
  });
}

async function displayChatRequests(requests) {
  if (!chatRequestsList) return;
  chatRequestsList.innerHTML = "";
  if (requests.length === 0) {
    chatRequestsList.innerHTML =
      '<div class="alert alert-info">No chat requests.</div>';
    return;
  }

  // Fetch user details for all unique userIds
  const userIds = [...new Set(requests.map((req) => req.userId))];
  const userDetails = {};
  for (const uid of userIds) {
    try {
      const userDoc = await getDoc(doc(db, "users", uid));
      if (userDoc.exists()) {
        userDetails[uid] = userDoc.data();
      }
    } catch (err) {
      console.error("Error fetching user:", uid, err);
      // Gracefully handle permission error by setting empty userInfo
      userDetails[uid] = {};
    }
  }

  // Remove duplicates based on req.id
  const uniqueRequests = requests.filter(
    (req, index, self) => index === self.findIndex((r) => r.id === req.id)
  );

  uniqueRequests.forEach((req) => {
    const userInfo = userDetails[req.userId] || {};
    const displayName = userInfo.name || userInfo.displayName || "Guest User";
    const phone = userInfo.phone || "N/A";

    const item = document.createElement("div");
    item.className =
      "list-group-item d-flex justify-content-between align-items-center";

    const left = document.createElement("div");
    left.innerHTML = `<strong>${displayName}</strong><br><small>${phone}</small><br><small class="text-muted">${
      req.message || "New chat request"
    } - ${
      req.createdAt ? new Date(req.createdAt.toDate()).toLocaleString() : "N/A"
    }</small>`;

    const right = document.createElement("div");
    right.className = "d-flex align-items-center gap-2";

    const badge = document.createElement("span");
    badge.className = "badge bg-primary rounded-pill";
    badge.textContent = req.status || "New";

    // Show unread count on chat requests for CX users
    const unreadCount = (req.cxUnreadCount ?? 0) || 0;
    if (unreadCount > 0) {
      const unreadBadge = document.createElement("span");
      unreadBadge.className = "badge bg-danger rounded-pill";
      unreadBadge.textContent = String(unreadCount);
      unreadBadge.style.fontWeight = "600";
      right.appendChild(unreadBadge);
    }

    const openBtn = document.createElement("button");
    openBtn.className = "btn btn-sm btn-outline-primary";
    openBtn.textContent = "Open";
    openBtn.addEventListener("click", (e) => {
      e.stopPropagation();
      openChat(req.id, req.userId, userInfo);
    });

    const acceptBtn = document.createElement("button");
    acceptBtn.className = "btn btn-sm btn-success";
    acceptBtn.textContent = "Accept";
    acceptBtn.addEventListener("click", async (e) => {
      e.stopPropagation();
      try {
        // Claim the chat: set cxId and status on chats/{chatId}
        const chatRef = doc(db, "chats", req.id);
        await updateDoc(chatRef, {
          status: "accepted",
          cxId: currentUser.cxId,
          acceptedAt: serverTimestamp(),
        });

        // Open chat after accepting
        openChat(req.id, req.userId, userInfo);
      } catch (err) {
        console.error("Error accepting chat request:", err);
        alert("Error accepting chat: " + (err.message || err));
      }
    });

    right.appendChild(badge);
    right.appendChild(openBtn);
    right.appendChild(acceptBtn);

    item.appendChild(left);
    item.appendChild(right);
    chatRequestsList.appendChild(item);
  });
}

async function openChat(chatId, userId, userInfo = {}) {
  const displayName = userInfo.name || userInfo.displayName || "Guest User";
  const phone = userInfo.phone || "N/A";
  const title = `${displayName} (${phone})`;

  // Check if tab already exists
  const existingTab = document.getElementById(`chat-tab-${chatId}`);
  if (existingTab) {
    // Activate it
    const tab = new bootstrap.Tab(existingTab);
    tab.show();
    return;
  }

  // Fetch chat status
  let chatStatus = "requested"; // default
  let chatData = {};
  try {
    const chatDoc = await getDoc(doc(db, "chats", chatId));
    if (chatDoc.exists()) {
      chatData = chatDoc.data();
      chatStatus = chatData.status || "requested";
    }
  } catch (error) {
    console.error("Error fetching chat status:", error);
  }

  const isAccepted = chatStatus === "accepted";

  // Add unread badge if any
  // const unreadCount = chatData.cxUnreadCount || 0;
  // let unreadBadgeHtml = "";
  // if (unreadCount > 0) {
  //   unreadBadgeHtml = `<span class="badge bg-danger rounded-pill ms-2" style="font-weight: 600; font-size: 0.75rem; padding: 0.25em 0.5em;">${unreadCount}</span>`;
  // }
  // const titleWithBadge = `${title}${unreadBadgeHtml}`;
  const titleWithBadge = `${title}`;

  // Create new tab
  const chatTabs = document.getElementById("chat-tabs");
  const chatTabsContent = document.getElementById("chat-tabs-content");

  // Create tab button
  const tabLi = document.createElement("li");
  tabLi.className = "nav-item";
  tabLi.role = "presentation";
  const tabBtn = document.createElement("button");
  tabBtn.className = "nav-link d-flex align-items-center";
  tabBtn.id = `chat-tab-${chatId}`;
  tabBtn.setAttribute("data-bs-toggle", "tab");
  tabBtn.setAttribute("data-bs-target", `#chat-content-${chatId}`);
  tabBtn.type = "button";
  tabBtn.role = "tab";
  tabBtn.innerHTML = `${titleWithBadge} <span class="ms-2 text-muted" style="cursor: pointer;" onclick="closeChatTab('${chatId}')">&times;</span>`;
  tabLi.appendChild(tabBtn);
  chatTabs.appendChild(tabLi);

  // Create tab content
  const tabPane = document.createElement("div");
  tabPane.className = "tab-pane fade";
  tabPane.id = `chat-content-${chatId}`;
  tabPane.role = "tabpanel";
  const acceptButtonHtml = !isAccepted
    ? `<button id="accept-chat-btn-${chatId}" class="btn btn-success">Accept Chat</button>`
    : "";
  const sendDisabled = !isAccepted ? "disabled" : "";
  tabPane.innerHTML = `
    <div style="height: 100%; display: flex; flex-direction: column;">
      <div class="chat-header p-2 bg-light border-bottom">
        <strong>${displayName}</strong> <small class="text-muted">(${phone})</small>
      </div>
  <div id="chat-messages-${chatId}" style="height: calc(60vh - 140px); overflow-y: auto; padding: 20px; box-sizing: border-box; background-color: #ffffffff; padding-bottom: 90px;"></div>
      <div class="d-flex gap-2 p-2 border-top" style="position: absolute; bottom: 0; left: 0; right: 0; background-color: #e9ecef; z-index: 10;">
        <input type="file" id="file-input-${chatId}" class="form-control" accept="image/*" style="display: none;" ${
    sendDisabled ? "disabled" : ""
  }>
        <button id="upload-btn-${chatId}" class="btn btn-outline-secondary" ${sendDisabled}>📎</button>
        <input type="text" id="chat-input-${chatId}" class="form-control" placeholder="Type a message..." ${
    sendDisabled ? "disabled" : ""
  }>
        <button id="send-btn-${chatId}" class="btn btn-primary" ${sendDisabled}>Send</button>
        ${acceptButtonHtml}
        <button id="close-chat-btn-${chatId}" class="btn btn-danger">Close Chat</button>
      </div>
    </div>
  `;
  chatTabsContent.appendChild(tabPane);

  // Show the open chats container
  const openChatsContainer = document.getElementById("open-chats-container");
  openChatsContainer.style.display = "flex";
  openChatsContainer.style.flexDirection = "column";
  openChatsContainer.style.position = "fixed";
  openChatsContainer.style.width = "40vw";
  openChatsContainer.style.height = "60vh";
  openChatsContainer.style.zIndex = "1000";
  openChatsContainer.style.border = "1px solid #ccc";
  openChatsContainer.style.backgroundColor = "#fff";
  openChatsContainer.style.boxShadow = "0 4px 8px rgba(247, 244, 244, 0.1)";
  openChatsContainer.style.overflow = "hidden";
  // Position at bottom right corner
  openChatsContainer.style.bottom = "20px";
  openChatsContainer.style.right = "20px";
  openChatsContainer.style.left = "auto";
  openChatsContainer.style.top = "auto";

  // Ensure minimize/maximize functionality is set up
  setupChatContainerControls();

  // Open maximized by default (no minimization)

  // Activate the tab
  const tab = new bootstrap.Tab(tabBtn);
  tab.show();

  // Switch to the Chats tab in the sidebar
  const chatSidebarTab = document.getElementById("v-pills-chat-tab");
  const sidebarTab = new bootstrap.Tab(chatSidebarTab);
  sidebarTab.show();

  // Set up chat
  const chatMessages = document.getElementById(`chat-messages-${chatId}`);
  const chatInput = document.getElementById(`chat-input-${chatId}`);
  const sendBtn = document.getElementById(`send-btn-${chatId}`);
  const closeChatBtn = document.getElementById(`close-chat-btn-${chatId}`);
  const acceptChatBtn = document.getElementById(`accept-chat-btn-${chatId}`);
  const uploadBtn = document.getElementById(`upload-btn-${chatId}`);
  const fileInput = document.getElementById(`file-input-${chatId}`);

  if (acceptChatBtn) {
    acceptChatBtn.addEventListener("click", async () => {
      try {
        await updateDoc(doc(db, "chats", chatId), {
          status: "accepted",
          cxId: currentUser.cxId,
          acceptedAt: serverTimestamp(),
        });
        // Enable input, send button, upload button, and file input
        chatInput.disabled = false;
        sendBtn.disabled = false;
        uploadBtn.disabled = false;
        fileInput.disabled = false;
        // Remove accept button
        acceptChatBtn.remove();
        console.log("Chat accepted:", chatId);
      } catch (error) {
        console.error("Error accepting chat:", error);
        alert("Error accepting chat: " + error.message);
      }
    });
  }

  // Set up file upload
  uploadBtn.addEventListener("click", () => {
    fileInput.click();
  });

  fileInput.addEventListener("change", async (e) => {
    const file = e.target.files[0];
    if (file) {
      // Upload to Firebase Storage
      const storageRef = ref(
        storage,
        `chat_attachments/${chatId}/${file.name}`
      );
      try {
        const snapshot = await uploadBytes(storageRef, file);
        const downloadURL = await getDownloadURL(snapshot.ref);
        // Send message with the URL
        await addDoc(collection(db, "chats", chatId, "messages"), {
          text: `Media: ${downloadURL}`,
          senderId: currentUser.cxId,
          timestamp: serverTimestamp(),
        });
        // Clear the input
        fileInput.value = "";
      } catch (error) {
        console.error("Error uploading file:", error);
        alert("Error uploading file: " + error.message);
      }
    }
  });

  // Listen to messages
  const messagesQuery = query(
    collection(db, "chats", chatId, "messages"),
    orderBy("timestamp", "asc")
  );
  const unsubscribe = onSnapshot(messagesQuery, async (snapshot) => {
    chatMessages.innerHTML = "";
    snapshot.docs.forEach((doc) => {
      const msg = doc.data();
      const msgDiv = document.createElement("div");
      msgDiv.className =
        msg.senderId === currentUser.cxId ? "text-end" : "text-start";

      let messageContent;
      if (msg.text.startsWith("Media: ")) {
        const url = msg.text.substring(7);
        const isImage = url.match(/\.(jpg|jpeg|png|gif|webp)$/i);
        if (isImage) {
          messageContent = `${
            msg.senderId === currentUser.cxId ? "CX" : displayName
          }:<br><img src="${url}" alt="Attachment" style="max-width: 200px; max-height: 200px; cursor: pointer; border-radius: 8px;" onclick="window.open('${url}', '_blank')">`;
        } else {
          messageContent = `${
            msg.senderId === currentUser.cxId ? "CX" : displayName
          }:<br><div style="display: inline-block; padding: 8px; background-color: #f8f9fa; border-radius: 8px; margin-top: 4px;"><strong>Attachment</strong><br><a href="${url}" target="_blank" style="color: #007bff; text-decoration: underline;">View Media</a></div>`;
        }
      } else {
        messageContent = `${
          msg.senderId === currentUser.cxId ? "CX" : displayName
        }:<strong> ${msg.text}</strong>`;
      }

      // Add timestamp under the message
      const timestamp = msg.timestamp
        ? new Date(msg.timestamp.toDate()).toLocaleString()
        : "N/A";
      messageContent += `<br><small class="text-muted">${timestamp}</small>`;

      // Add status for CX messages
      if (msg.senderId === currentUser.cxId) {
        messageContent += ` <small class="text-muted">Sent</small>`;
      }

      msgDiv.innerHTML = messageContent;
      chatMessages.appendChild(msgDiv);
    });
    // Scroll to bottom after DOM update so the newest message is visible.
    // Use requestAnimationFrame twice and a small timeout as a robust fallback across browsers.
    const scrollToBottom = () => {
      try {
        chatMessages.scrollTop = chatMessages.scrollHeight;
      } catch (e) {
        // ignore
      }
    };
    requestAnimationFrame(() => {
      requestAnimationFrame(scrollToBottom);
      setTimeout(scrollToBottom, 50);
    });

    // Only clear unread count if this chat tab is currently active/visible
    // Removed this because the because the unread badge in title will help the cx to remember that he has to reply to them.
    // Uncomment the below lines so that you can enable this feature.
    // const activeTab = document.querySelector("#chat-tabs .nav-link.active");
    // if (activeTab && activeTab.id === `chat-tab-${chatId}`) {
    //   try {
    //     await updateDoc(doc(db, "chats", chatId), {
    //       cxUnreadCount: 0,
    //     });
    //   } catch (error) {
    //     console.error("Error clearing unread count:", error);
    //   }
    // }
  });

  sendBtn.addEventListener("click", async () => {
    const text = chatInput.value.trim();
    if (text) {
      await addDoc(collection(db, "chats", chatId, "messages"), {
        text,
        senderId: currentUser.cxId,
        timestamp: serverTimestamp(),
      });
      // After CX sends a message, clear unread counters (CX authored messages should not be counted as unread by CX)
      try {
        await updateDoc(doc(db, "chats", chatId), {
          cxUnreadCount: 0,
        });
      } catch (e) {
        console.error("Error clearing unread on send", chatId, e);
      }
      chatInput.value = "";
    }
  });

  chatInput.addEventListener("keypress", (e) => {
    if (e.key === "Enter") sendBtn.click();
  });

  closeChatBtn.addEventListener("click", async () => {
    if (
      !confirm(
        "Are you sure you want to close this chat? This will terminate the chat for both sides."
      )
    )
      return;
    try {
      await updateDoc(doc(db, "chats", chatId), {
        status: "closed",
        closedAt: serverTimestamp(),
        closedBy: currentUser.cxId,
      });
      alert("Chat closed successfully.");
      // Remove tab
      chatTabs.removeChild(tabLi);
      chatTabsContent.removeChild(tabPane);
      unsubscribe();
    } catch (error) {
      console.error("Error closing chat:", error);
      alert("Error closing chat: " + error.message);
    }
  });
}

window.openBookingChat = async (bookingId, userId) => {
  console.log("Opening chat for booking:", bookingId, "user:", userId);
  // Fetch booking details
  let booking = null;
  try {
    console.log("Fetching booking document:", bookingId);
    const bookingDoc = await getDoc(doc(db, "bookings", bookingId));
    console.log("Booking doc exists:", bookingDoc.exists());
    booking = bookingDoc.exists() ? bookingDoc.data() : null;

    if (!booking) {
      console.error("Booking not found for ID:", bookingId);
      alert("Booking not found");
      return;
    }
    console.log("Booking data:", booking);
  } catch (error) {
    console.error("Error fetching booking:", error);
    alert("Error fetching booking: " + error.message);
    return;
  }

  // Fetch user details
  let userInfo = {};
  try {
    const userDoc = await getDoc(doc(db, "users", userId));
    console.log("User info:", userDoc.exists(), userDoc.data());
    if (userDoc.exists()) {
      userInfo = userDoc.data();
    }
  } catch (error) {
    console.error("Error fetching user:", error);
  }
  const displayName = userInfo.name || userInfo.displayName || "Guest User";
  const phone = userInfo.phone || "N/A";

  // Find or create chat for this booking
  // We must use the actual Firestore document id for the chat (not assume bookingId)
  let chatId = null;
  // Prefer deterministic chat doc id to avoid duplicates
  const deterministicId = `booking_${bookingId}`;
  const deterministicRef = doc(db, "chats", deterministicId);
  const detSnap = await getDoc(deterministicRef);
  if (detSnap.exists()) {
    chatId = deterministicId;
  } else {
    // Backcompat: maybe a chat exists with random id and bookingId field
    const existingChatQ = query(
      collection(db, "chats"),
      where("bookingId", "==", bookingId)
    );
    const chatQuerySnap = await getDocs(existingChatQ);
    if (!chatQuerySnap.empty) {
      chatId = chatQuerySnap.docs[0].id;
    } else {
      // Create deterministic doc
      await setDoc(deterministicRef, {
        bookingId,
        userId,
        cxId: currentUser.cxId,
        createdAt: serverTimestamp(),
        status: "accepted",
      });
      chatId = deterministicId;
    }
  }

  // Use the same openChat function for consistency
  openChat(chatId, userId, userInfo);
};

function initializeDateFilters() {
  // Initialize Flatpickr for date range picker
  dateRangePickerInstance = flatpickr("#date-range-picker", {
    mode: "range",
    dateFormat: "Y-m-d",
    onChange: (selectedDates, dateStr, instance) => {
      if (selectedDates.length === 2) {
        displayBookings(bookings);
      }
    },
  });

  // Toggle advanced filters
  advancedFiltersToggle.addEventListener("click", () => {
    const isVisible = advancedFilters.style.display !== "none";
    if (isVisible) {
      advancedFilters.style.display = "none";
      advancedFiltersToggle.classList.remove("btn-danger");
      advancedFiltersToggle.classList.add("btn-success");
      advancedFiltersToggle.innerHTML =
        'Advanced Filters <i class="bi bi-chevron-down"></i>';
    } else {
      advancedFilters.style.display = "block";
      advancedFiltersToggle.classList.remove("btn-success");
      advancedFiltersToggle.classList.add("btn-danger");
      advancedFiltersToggle.innerHTML =
        'Advanced Filters <i class="bi bi-chevron-up"></i>';
    }
  });

  // Quick date filter change
  quickDateFilter.addEventListener("change", () => {
    const value = quickDateFilter.value;
    if (value) {
      const today = new Date();
      let startDate, endDate;

      switch (value) {
        case "today":
          startDate = new Date(today);
          endDate = new Date(today);
          break;
        case "yesterday":
          startDate = new Date(today);
          startDate.setDate(today.getDate() - 1);
          endDate = new Date(startDate);
          break;
        case "this-week":
          startDate = new Date(today);
          startDate.setDate(today.getDate() - today.getDay());
          endDate = new Date(today);
          break;
        case "last-7-days":
          startDate = new Date(today);
          startDate.setDate(today.getDate() - 7);
          endDate = new Date(today);
          break;
        case "this-month":
          startDate = new Date(today.getFullYear(), today.getMonth(), 1);
          endDate = new Date(today);
          break;
      }

      if (startDate && endDate) {
        dateRangePickerInstance.setDate([startDate, endDate]);
        displayBookings(bookings);
      }
    } else {
      dateRangePickerInstance.clear();
      displayBookings(bookings);
    }
  });

  // Clear filters button
  clearFiltersBtn.addEventListener("click", () => {
    // Reset all filter elements to default values
    serviceFilter.value = "";
    statusFilter.value = "";
    agentFilter.value = "";
    quickDateFilter.value = "";
    dateRangePickerInstance.clear();

    // Re-display all bookings
    displayBookings(bookings);
  });
}

function filterBookings(bookings) {
  const service = serviceFilter.value;
  const status = statusFilter.value;
  const agent = agentFilter.value;
  const dateRange = dateRangePickerInstance.selectedDates;

  return bookings.filter((booking) => {
    const serviceName =
      servicesList.find((s) => s.id === booking.serviceId)?.name ||
      booking.service ||
      booking.serviceName;
    const agentId = booking.agentId || "";

    // Service filter
    const serviceMatch =
      !service || serviceName.toLowerCase().includes(service.toLowerCase());

    // Status filter
    const statusMatch =
      !status || booking.status.toLowerCase() === status.toLowerCase();

    // Agent filter
    const agentMatch = !agent || agentId === agent;

    // Date filter
    let dateMatch = true;
    if (dateRange && dateRange.length === 2) {
      const bookingDate = booking.createdAt ? booking.createdAt.toDate() : null;
      if (bookingDate) {
        const startDate = new Date(dateRange[0]);
        startDate.setHours(0, 0, 0, 0);
        const endDate = new Date(dateRange[1]);
        endDate.setHours(23, 59, 59, 999);
        dateMatch = bookingDate >= startDate && bookingDate <= endDate;
      }
    }

    return serviceMatch && statusMatch && agentMatch && dateMatch;
  });
}

function initializeSlots() {
  // Set minimum date to today
  const today = new Date().toISOString().split("T")[0];
  slotDate.min = today;
  slotDate.value = today;

  // Generate time slot buttons
  generateTimeSlots();

  // Event listener for date change
  slotDate.addEventListener("change", loadSlotsForDate);

  // Event listener for save slots button
  const saveSlotsBtn = document.getElementById("save-slots-btn");
  saveSlotsBtn.addEventListener("click", saveSlots);

  // Load and display current slots
  loadSlots();
}

function generateTimeSlots() {
  const timeSlotsGrid = document.getElementById("time-slots-grid");
  timeSlotsGrid.innerHTML = "";
  const startHour = 9;
  const endHour = 17; // 5 PM
  for (let hour = startHour; hour <= endHour; hour++) {
    const time = `${hour.toString().padStart(2, "0")}:00`;
    const button = document.createElement("button");
    button.type = "button";
    button.className = "btn btn-outline-primary m-1 time-slot-btn";
    button.textContent = time;
    button.dataset.time = time;
    button.addEventListener("click", () => toggleTimeSlot(button));
    timeSlotsGrid.appendChild(button);
  }
}

function toggleTimeSlot(button) {
  button.classList.toggle("btn-primary");
  button.classList.toggle("btn-outline-primary");
}

async function loadSlotsForDate() {
  const date = slotDate.value;
  if (!date) return;

  try {
    const slotDoc = await getDoc(doc(db, "available_slots", date));
    const slotData = slotDoc.exists() ? slotDoc.data() : { slots: [] };
    const selectedTimes = slotData.slots || [];

    // Reset all buttons
    const buttons = document.querySelectorAll(".time-slot-btn");
    buttons.forEach((btn) => {
      btn.classList.remove("btn-primary");
      btn.classList.add("btn-outline-primary");
    });

    // Mark selected slots
    selectedTimes.forEach((time) => {
      const button = document.querySelector(
        `.time-slot-btn[data-time="${time}"]`
      );
      if (button) {
        button.classList.remove("btn-outline-primary");
        button.classList.add("btn-primary");
      }
    });
  } catch (error) {
    console.error("Error loading slots for date:", error);
    alert("Error loading slots for date: " + error.message);
  }
}

async function saveSlots() {
  const date = slotDate.value;
  if (!date) {
    alert("Please select a date");
    return;
  }

  const selectedButtons = document.querySelectorAll(
    ".time-slot-btn.btn-primary"
  );
  const selectedTimes = Array.from(selectedButtons).map(
    (btn) => btn.dataset.time
  );

  try {
    await setDoc(doc(db, "available_slots", date), {
      slots: selectedTimes,
      createdAt: new Date(),
    });

    alert("Slots saved successfully");
    loadSlots(); // Refresh the display
  } catch (error) {
    console.error("Error saving slots:", error);
    alert("Error saving slots: " + error.message);
  }
}

async function addSlot() {
  const date = slotDate.value;
  const time = slotTime.value;
  const agentId = document.getElementById("slot-agent").value;

  if (!date || !time || !agentId) {
    alert("Please fill in all fields");
    return;
  }

  try {
    // Check if slot already exists
    const existingSlotsQuery = query(
      collection(db, "slots"),
      where("agentId", "==", agentId),
      where("date", "==", date),
      where("time", "==", time)
    );
    const existingSlots = await getDocs(existingSlotsQuery);

    if (!existingSlots.empty) {
      alert("This slot already exists for the selected agent and date");
      return;
    }

    await addDoc(collection(db, "slots"), {
      agentId,
      date,
      time,
      createdAt: new Date(),
      status: "available",
    });
    alert("Slot added successfully");
    slotTime.value = "";
    loadSlots();
  } catch (error) {
    console.error("Error adding slot:", error);
    alert("Error adding slot: " + error.message);
  }
}

async function loadSlots() {
  try {
    const slotsSnapshot = await getDocs(collection(db, "available_slots"));
    const slots = slotsSnapshot.docs
      .map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }))
      .sort((a, b) => a.id.localeCompare(b.id));
    console.log("Loaded slots:", slots);
    displaySlots(slots);
  } catch (error) {
    console.error("Error loading slots:", error);
  }
}

function displaySlots(slots) {
  currentSlots.innerHTML = "";
  if (slots.length === 0) {
    currentSlots.innerHTML =
      '<div class="alert alert-info">No slots available.</div>';
    return;
  }

  slots.forEach((slot) => {
    const slotDiv = document.createElement("div");
    slotDiv.className = "card mb-3";
    slotDiv.innerHTML = `
      <div class="card-body">
        <h6 class="card-title">${new Date(slot.id).toLocaleDateString()}</h6>
        <p class="card-text">Available times: ${slot.slots.join(", ")}</p>
        <button class="btn btn-danger btn-sm" onclick="deleteSlots('${
          slot.id
        }')">Delete All</button>
      </div>
    `;
    currentSlots.appendChild(slotDiv);
  });
}

window.deleteSlots = async (date) => {
  if (!confirm("Are you sure you want to delete all slots for this date?"))
    return;

  try {
    await deleteDoc(doc(db, "available_slots", date));
    alert("Slots deleted successfully");
    loadSlots();
  } catch (error) {
    console.error("Error deleting slots:", error);
    alert("Error deleting slots: " + error.message);
  }
};

window.closeChatTab = async (chatId) => {
  if (!confirm("Are you sure you want to close this chat tab?")) return;

  // Reset unread count when closing the tab (CX has "read" by closing)
  // try {
  //   await updateDoc(doc(db, "chats", chatId), {
  //     cxUnreadCount: 0,
  //   });
  // } catch (error) {
  //   console.error("Error resetting unread count:", error);
  // }

  // Remove tab and content
  const tabLi = document.getElementById(`chat-tab-${chatId}`).parentElement;
  const tabPane = document.getElementById(`chat-content-${chatId}`);
  const chatTabs = document.getElementById("chat-tabs");
  const chatTabsContent = document.getElementById("chat-tabs-content");

  if (tabLi && chatTabs) chatTabs.removeChild(tabLi);
  if (tabPane && chatTabsContent) chatTabsContent.removeChild(tabPane);

  // If no more tabs, hide the container
  const remainingTabs = chatTabs.querySelectorAll(".nav-link");
  if (remainingTabs.length === 0) {
    const openChatsContainer = document.getElementById("open-chats-container");
    openChatsContainer.style.display = "none";
  } else {
    // Activate the first remaining tab
    const firstTab = remainingTabs[0];
    const tab = new bootstrap.Tab(firstTab);
    tab.show();
  }
};

function setupChatContainerControls() {
  const openChatsContainer = document.getElementById("open-chats-container");

  // Check if controls are already added
  if (openChatsContainer.querySelector(".chat-controls")) return;

  // Create controls div
  const controlsDiv = document.createElement("div");
  controlsDiv.className =
    "chat-controls d-flex justify-content-end p-2 bg-light border-bottom";
  controlsDiv.innerHTML = `
    <button id="close-chat-container-btn" class="btn btn-sm btn-outline-danger me-1">Close</button>
    <button id="minimize-chat-btn" class="btn btn-sm btn-outline-secondary me-1">Minimize</button>
    <button id="maximize-chat-btn" class="btn btn-sm btn-outline-secondary" style="display:none;">Maximize</button>
  `;

  // Insert at the top of the container
  openChatsContainer.insertBefore(controlsDiv, openChatsContainer.firstChild);

  // Add event listeners
  const closeBtn = document.getElementById("close-chat-container-btn");
  const minimizeBtn = document.getElementById("minimize-chat-btn");
  const maximizeBtn = document.getElementById("maximize-chat-btn");

  closeBtn.addEventListener("click", () => {
    // Close all open chat tabs and hide the container
    const chatTabs = document.getElementById("chat-tabs");
    const chatTabsContent = document.getElementById("chat-tabs-content");

    // Remove all tabs
    while (chatTabs.firstChild) {
      chatTabs.removeChild(chatTabs.firstChild);
    }

    // Remove all tab content
    while (chatTabsContent.firstChild) {
      chatTabsContent.removeChild(chatTabsContent.firstChild);
    }

    // Hide the container
    openChatsContainer.style.display = "none";
  });

  minimizeBtn.addEventListener("click", () => {
    // Minimize: hide the content, show only tabs or a small bar
    const chatTabsContent = document.getElementById("chat-tabs-content");
    chatTabsContent.style.display = "none";
    minimizeBtn.style.display = "none";
    maximizeBtn.style.display = "inline-block";
    // Set minimized height
    openChatsContainer.style.height = "50px";
    // Disable close button when minimized
    closeBtn.disabled = true;
  });

  maximizeBtn.addEventListener("click", () => {
    // Maximize: show content
    const chatTabsContent = document.getElementById("chat-tabs-content");
    chatTabsContent.style.display = "block";
    minimizeBtn.style.display = "inline-block";
    maximizeBtn.style.display = "none";
    // Set maximized height
    openChatsContainer.style.height = "60vh";
    // Enable close button when maximized
    closeBtn.disabled = false;
  });
}
