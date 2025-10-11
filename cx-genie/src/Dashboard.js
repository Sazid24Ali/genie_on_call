import React, { useState, useEffect } from "react";
import {
  collection,
  query,
  where,
  onSnapshot,
  updateDoc,
  doc,
  getDocs,
} from "firebase/firestore";
import { db, auth } from "./firebase";
import ChatInterface from "./ChatInterface";

function Dashboard() {
  const [activeTab, setActiveTab] = useState("pending");
  const [pendingBookings, setPendingBookings] = useState([]);
  const [agents, setAgents] = useState([]);
  const [chats, setChats] = useState([]);
  const [selectedChat, setSelectedChat] = useState(null);
  const [agentBookings, setAgentBookings] = useState([]);

  useEffect(() => {
    // Fetch pending bookings
    const q = query(
      collection(db, "bookings"),
      where("status", "==", "pending")
    );
    const unsubscribe = onSnapshot(q, (querySnapshot) => {
      const bookings = [];
      querySnapshot.forEach((doc) => {
        bookings.push({ id: doc.id, ...doc.data() });
      });
      setPendingBookings(bookings);
    });

    // Fetch agents
    const agentsQuery = collection(db, "agents");
    const agentsUnsubscribe = onSnapshot(agentsQuery, (querySnapshot) => {
      const agentsList = [];
      querySnapshot.forEach((doc) => {
        agentsList.push({ id: doc.id, ...doc.data() });
      });
      setAgents(agentsList);
    });

    // Fetch chats
    const chatsQuery = collection(db, "chats");
    const chatsUnsubscribe = onSnapshot(chatsQuery, (querySnapshot) => {
      const chatsList = [];
      querySnapshot.forEach((doc) => {
        chatsList.push({ id: doc.id, ...doc.data() });
      });
      setChats(chatsList);
    });

    return () => {
      unsubscribe();
      agentsUnsubscribe();
      chatsUnsubscribe();
    };
  }, []);

  const assignAgent = async (bookingId, agentId) => {
    await updateDoc(doc(db, "bookings", bookingId), {
      assignedAgentId: agentId,
      status: "assigned",
    });
    // Add CX and agent to chat participants
    const booking = pendingBookings.find((b) => b.id === bookingId);
    if (booking && booking.chatId) {
      await updateDoc(doc(db, "chats", booking.chatId), {
        participants: [booking.userId, agentId, auth.currentUser.uid],
      });
    }
  };

  const viewAgentBookings = async (agentId) => {
    const q = query(
      collection(db, "bookings"),
      where("assignedAgentId", "==", agentId)
    );
    const querySnapshot = await getDocs(q);
    const bookings = [];
    querySnapshot.forEach((doc) => {
      bookings.push({ id: doc.id, ...doc.data() });
    });
    setAgentBookings(bookings);
  };

  return (
    <div>
      <h1>CX Dashboard</h1>
      <div>
        <button onClick={() => setActiveTab("pending")}>
          Pending Bookings
        </button>
        <button onClick={() => setActiveTab("chats")}>Active Chats</button>
        <button onClick={() => setActiveTab("agents")}>Agent Bookings</button>
      </div>
      {activeTab === "pending" && (
        <div>
          <h2>Pending Bookings</h2>
          {pendingBookings.map((booking) => (
            <div key={booking.id}>
              <p>Service: {booking.serviceName}</p>
              <p>User: {booking.userName}</p>
              <select onChange={(e) => assignAgent(booking.id, e.target.value)}>
                <option>Select Agent</option>
                {agents.map((agent) => (
                  <option key={agent.id} value={agent.id}>
                    {agent.name}
                  </option>
                ))}
              </select>
            </div>
          ))}
        </div>
      )}
      {activeTab === "chats" && (
        <div>
          <h2>Active Chats</h2>
          {chats.map((chat) => (
            <div key={chat.id}>
              <p>Chat ID: {chat.id}</p>
              <button onClick={() => setSelectedChat(chat.id)}>
                Open Chat
              </button>
            </div>
          ))}
          {selectedChat && <ChatInterface chatId={selectedChat} />}
        </div>
      )}
      {activeTab === "agents" && (
        <div>
          <h2>Agent Bookings</h2>
          <select onChange={(e) => viewAgentBookings(e.target.value)}>
            <option>Select Agent</option>
            {agents.map((agent) => (
              <option key={agent.id} value={agent.id}>
                {agent.name}
              </option>
            ))}
          </select>
          {agentBookings.map((booking) => (
            <div key={booking.id}>
              <p>Service: {booking.serviceName}</p>
              <p>Status: {booking.status}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default Dashboard;
