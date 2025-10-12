import { initializeApp } from "https://www.gstatic.com/firebasejs/9.22.0/firebase-app.js";
import {
  getFirestore,
  collection,
  getDocs,
  doc,
  getDoc,
  updateDoc,
  onSnapshot,
  addDoc,
  query,
  orderBy,
  where,
} from "https://www.gstatic.com/firebasejs/9.22.0/firebase-firestore.js";

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

let currentUser = null;
let agents = [];
let servicesList = [];
let bookings = [];
let chatRequests = [];
let bookingsUnsubscribe = null;
let chatRequestsUnsubscribe = null;

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
let selectedAgentServices = [];

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
      (u) => u.cx_id === cxId && u.password === password
    );
    if (user) {
      currentUser = { cx_id: user.cx_id };
      localStorage.setItem("cxUser", JSON.stringify(currentUser));
      showDashboard();
      loadData();
      console.log("Logged in as:", currentUser.cx_id);
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
  setupBookingsListener();
  setupChatRequestsListener();
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

function filterBookings(bookings) {
  const service = serviceFilter.value;
  const status = statusFilter.value;
  const agent = agentFilter.value;
  const dateFrom = dateFromInput.value ? new Date(dateFromInput.value) : null;
  const dateTo = dateToInput.value ? new Date(dateToInput.value) : null;
  return bookings.filter((booking) => {
    const serviceName =
      servicesList.find((s) => s.id === booking.serviceId)?.name ||
      booking.service ||
      booking.serviceName;
    const agentId = booking.agentId || "";
    const bookingDate = booking.createdAt ? booking.createdAt.toDate() : null;
    const dateMatch =
      (!dateFrom || !bookingDate || bookingDate >= dateFrom) &&
      (!dateTo || !bookingDate || bookingDate <= dateTo);
    return (
      (!service || serviceName.toLowerCase().includes(service.toLowerCase())) &&
      (!status || booking.status.toLowerCase() === status.toLowerCase()) &&
      (!agent || agentId === agent) &&
      dateMatch
    );
  });
}

serviceFilter.addEventListener("change", () => displayBookings(bookings));
statusFilter.addEventListener("change", () => displayBookings(bookings));
agentFilter.addEventListener("change", () => displayBookings(bookings));

const dateFromInput = document.getElementById("date-from");
const dateToInput = document.getElementById("date-to");
dateFromInput.addEventListener("change", () => displayBookings(bookings));
dateToInput.addEventListener("change", () => displayBookings(bookings));

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
    collection(db, "chat_requests"),
    orderBy("timestamp", "desc")
  );
  chatRequestsUnsubscribe = onSnapshot(chatRequestsQuery, (snapshot) => {
    chatRequests = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    displayChatRequests(chatRequests);
  });
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

function displayChatRequests(requests) {
  chatRequestsList.innerHTML = "";
  if (requests.length === 0) {
    chatRequestsList.innerHTML =
      '<div class="alert alert-info">No chat requests.</div>';
    return;
  }
  requests.forEach((req) => {
    const item = document.createElement("a");
    item.className =
      "list-group-item list-group-item-action d-flex justify-content-between align-items-center";
    item.innerHTML = `
      <div>
        <strong>${req.userName || req.userId}</strong><br>
        <small class="text-muted">${req.message || "New chat request"} - ${
      req.timestamp ? new Date(req.timestamp.toDate()).toLocaleString() : "N/A"
    }</small>
      </div>
      <span class="badge bg-primary rounded-pill">New</span>
    `;
    item.onclick = () => openChat(req.id, req.userId);
    chatRequestsList.appendChild(item);
  });
}

function openChat(chatId, userId) {
  // Create a modal for chat
  const modal = document.createElement("div");
  modal.className = "modal fade";
  modal.id = "chatModal";
  modal.innerHTML = `
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Chat with ${userId}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div id="chat-messages" style="height: 300px; overflow-y: auto; border: 1px solid #ccc; padding: 10px;"></div>
          <div class="mt-3">
            <input type="text" id="chat-input" class="form-control" placeholder="Type a message...">
            <button id="send-btn" class="btn btn-primary mt-2">Send</button>
          </div>
        </div>
      </div>
    </div>
  `;
  document.body.appendChild(modal);

  const chatMessages = document.getElementById("chat-messages");
  const chatInput = document.getElementById("chat-input");
  const sendBtn = document.getElementById("send-btn");

  // Listen to messages
  const messagesQuery = query(
    collection(db, "chats", chatId, "messages"),
    orderBy("timestamp", "asc")
  );
  const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
    chatMessages.innerHTML = "";
    snapshot.docs.forEach((doc) => {
      const msg = doc.data();
      const msgDiv = document.createElement("div");
      msgDiv.className =
        msg.senderId === currentUser.cx_id ? "text-end" : "text-start";
      msgDiv.innerHTML = `<strong>${
        msg.senderId === currentUser.cx_id ? "CX" : userId
      }:</strong> ${msg.text}`;
      chatMessages.appendChild(msgDiv);
    });
    chatMessages.scrollTop = chatMessages.scrollHeight;
  });

  sendBtn.addEventListener("click", async () => {
    const text = chatInput.value.trim();
    if (text) {
      await addDoc(collection(db, "chats", chatId, "messages"), {
        text,
        senderId: currentUser.cx_id,
        timestamp: new Date(),
      });
      chatInput.value = "";
    }
  });

  chatInput.addEventListener("keypress", (e) => {
    if (e.key === "Enter") sendBtn.click();
  });

  // Show modal
  const bsModal = new bootstrap.Modal(modal);
  bsModal.show();

  // Clean up on close
  modal.addEventListener("hidden.bs.modal", () => {
    unsubscribe();
    document.body.removeChild(modal);
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

  // Find or create chat for this booking
  let chatId = bookingId; // Use bookingId as chatId for simplicity

  // Check if chat exists, if not create it
  const chatDoc = await getDocs(
    query(collection(db, "chats"), where("bookingId", "==", bookingId))
  );
  if (chatDoc.empty) {
    // Create new chat document
    await addDoc(collection(db, "chats"), {
      bookingId,
      userId,
      cxId: currentUser.cx_id,
      createdAt: new Date(),
    });
  } else {
    chatId = chatDoc.docs[0].id;
  }

  // Create a modal for chat with booking details
  const modal = document.createElement("div");
  modal.className = "modal fade";
  modal.id = "chatModal";
  const serviceName =
    servicesList.find((s) => s.id === booking.serviceId)?.name ||
    booking.service ||
    booking.serviceName;
  const agentName =
    agents.find((a) => a.id === booking.agentId)?.name || "Unassigned";
  const bookingDate = booking.bookingDate
    ? new Date(booking.bookingDate.toDate()).toLocaleDateString()
    : "N/A";
  const bookingTime = booking.bookingTime || "N/A";
  const imagesSection =
    booking.images && booking.images.length > 0
      ? `<div class="mb-3"><strong>Images:</strong><br>${booking.images
          .map(
            (img) =>
              `<a href="${img}" target="_blank" class="text-decoration-none">View Image</a>`
          )
          .join("<br>")}</div>`
      : "";
  const recordingSection = booking.recording
    ? `<div class="mb-3"><strong>Recording:</strong><br><a href="${booking.recording}" target="_blank" class="text-decoration-none">View Recording</a></div>`
    : "";
  const cxName = "CX";
  const userName = booking.userName || userId;
  modal.innerHTML = `
    <div class="modal-dialog modal-xl">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Chat with ${userName} - ${serviceName}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="row">
            <div class="col-md-5">
              <h6>Booking Details</h6>
              <p><strong>Service:</strong> ${serviceName}</p>
              <p><strong>Status:</strong> <span class="badge bg-${getStatusBadgeClass(
                booking.status
              )}">${booking.status}</span></p>
              <p><strong>User:</strong> ${
                booking.userName || booking.userId
              }</p>
              <p><strong>Phone:</strong> ${booking.userPhone}</p>
              <p><strong>Address:</strong> ${booking.userAddress}</p>
              <p><strong>Date/Time:</strong> ${bookingDate} at ${bookingTime}</p>
              <p><strong>Cost:</strong> ₹${booking.cost}</p>
              <p><strong>Description:</strong> ${booking.description || "-"}</p>
              <p><strong>Agent:</strong> ${agentName}</p>
              ${imagesSection}
              ${recordingSection}
            </div>
            <div class="col-md-7">
              <h6>Chat Messages</h6>
              <div id="chat-messages" style="height: 300px; overflow-y: auto; border: 1px solid #ccc; padding: 10px;"></div>
              <div class="mt-3">
                <input type="text" id="chat-input" class="form-control" placeholder="Type a message...">
                <button id="send-btn" class="btn btn-primary mt-2">Send</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  `;
  document.body.appendChild(modal);

  const chatMessages = document.getElementById("chat-messages");
  const chatInput = document.getElementById("chat-input");
  const sendBtn = document.getElementById("send-btn");

  // Listen to messages
  const messagesQuery = query(
    collection(db, "chats", chatId, "messages"),
    orderBy("timestamp", "asc")
  );
  const unsubscribe = onSnapshot(messagesQuery, (snapshot) => {
    chatMessages.innerHTML = "";
    snapshot.docs.forEach((doc) => {
      const msg = doc.data();
      const msgDiv = document.createElement("div");
      msgDiv.className =
        msg.senderId === currentUser.cx_id ? "text-end" : "text-start";
      msgDiv.innerHTML = `<strong>${msg.senderId}:</strong> ${msg.text}`;
      chatMessages.appendChild(msgDiv);
    });
    chatMessages.scrollTop = chatMessages.scrollHeight;
  });

  sendBtn.addEventListener("click", async () => {
    const text = chatInput.value.trim();
    if (text) {
      await addDoc(collection(db, "chats", chatId, "messages"), {
        text,
        senderId: currentUser.cx_id,
        timestamp: new Date(),
      });
      chatInput.value = "";
    }
  });

  chatInput.addEventListener("keypress", (e) => {
    if (e.key === "Enter") sendBtn.click();
  });

  // Show modal
  const bsModal = new bootstrap.Modal(modal);
  bsModal.show();

  // Clean up on close
  modal.addEventListener("hidden.bs.modal", () => {
    unsubscribe();
    document.body.removeChild(modal);
  });
};
