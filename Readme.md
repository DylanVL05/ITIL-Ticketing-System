# 🛠️ ITIL Ticketing System

A modular and scalable ITIL-based ticketing and monitoring system designed to provide effective IT support, service operation, and infrastructure monitoring using GLPI, Zabbix, and a custom front-end interface.

---

## 📌 Overview

This project implements an **ITIL-compliant Service Operation system** using open-source technologies to manage incidents, problems, and changes within an IT infrastructure. It includes automated alert scripts, REST API integration, and dual server architecture.

---

## 🧱 Architecture

The system is composed of two main Ubuntu servers:

### 🖥️ Server A – Central Operations
- Apache Web Server
- GLPI (Ticket Management)
- MariaDB (Database)
- Hosts both Admin and End-User front-end interfaces
- Exposes GLPI REST API for integration

### 🖥️ Server B – Monitoring Node
- Zabbix Monitoring
- Cron-based Ticket Alert Scripts
- Sends alerts to Server A via GLPI REST API

---

## 🔁 ITIL Service Operation Process Flow

The system covers the following ITIL processes:

1. **Incident Management**  
   Detects and logs incidents either manually (users) or automatically (monitoring).
   
2. **Problem Management**  
   Links related incidents and escalates them to root cause analysis.
   
3. **Change Management**  
   Applies structured changes based on problem resolution.
   
4. **Ticket Closure**  
   Final state after resolution and verification.
   
5. **Resolution**  
   Either resolves the incident or escalates it to problem management.

---

## 🌐 User Interfaces

- **End-User Website**:  
  A simple web interface where users can create their tickets.
  
- **Admin Interface (GLPI)**:  
  Full access to all ITIL processes, asset management, user roles, and ticket workflows.

Both interfaces communicate with the GLPI back-end using the **GLPI REST API**.

---

## 🔗 GLPI REST API

The project relies on the GLPI API to:
- Create tickets from monitoring alerts
- Authenticate users
- Retrieve ticket status
- Manage user roles and permissions

---

## 🚨 Automated Monitoring & Alerting

Zabbix is used to monitor:
- CPU
- RAM
- Disk
- Network
- Temperature

When thresholds are exceeded:
- Alert scripts trigger a GLPI API call
- A ticket is generated automatically with severity and category

---

## 🧪 Technologies Used

| Component     | Technology       |
|---------------|------------------|
| OS            | Ubuntu Server 24.04 |
| Web Server    | Apache 2.4       |
| Ticket System | GLPI             |
| Database      | MariaDB          |
| Monitoring    | Zabbix 7         |
| Scripting     | Bash + Cron or Daemon    |
| API           | GLPI REST API    |
| Front-End     | HTML, CSS, JS (Admin & User Panels) |

---

## 🧑‍💻 Author

**Dylan Venegas**  
Systems Engineering Student - Costa Rica  
Project focused on IT Support Automation & ITIL Processes

---

## 📌 License

This project is open-source and free to use under the MIT License.

