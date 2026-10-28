# Railway Reservation System — Java Swing + MySQL JDBC

A complete, production-grade, desktop **Railway Reservation System** built with **Java Swing (GUI)**, **MySQL 8+**, and **JDBC**. Designed with an enterprise **MVC (Model-View-Controller)** pattern with distinct **DAO (Data Access Object)** and **Service** layers, featuring **BCrypt** password hashing, database transaction management with row-level locking (`SELECT ... FOR UPDATE`), and seamless compatibility with **Eclipse IDE** and **Maven**.

---

## 1. Technology Stack & Architecture

- **Language:** Java 17 or later (tested on OpenJDK 25 LTS)
- **GUI Framework:** Java Swing with responsive Layout Managers (`BorderLayout`, `GridBagLayout`, `BoxLayout`, `GridLayout`)
- **Database:** MySQL 8.0+
- **Database Connectivity:** JDBC using official MySQL Connector/J driver (`com.mysql.cj.jdbc.Driver`)
- **Build Tool:** Apache Maven (`pom.xml`)
- **Password Security:** OpenBSD BCrypt hashing (`org.mindrot:jbcrypt`) with cost factor 12
- **Testing:** JUnit 5 (`org.junit.jupiter`)
- **IDE Compatibility:** Eclipse IDE (with Maven m2e), IntelliJ IDEA, NetBeans, Command Line

### Architectural Layers
```
┌────────────────────────────────────────────────────────┐
│                      VIEW (Swing)                      │
│ LoginFrame | RegisterFrame | DashboardFrame           │
│ TrainSearchFrame | BookingFrame | MyBookingsFrame     │
│ AdminFrame | TicketDetailDialog | Custom UI Components │
└───────────────────────────┬────────────────────────────┘
                            │ SwingWorker (Async UI)
┌───────────────────────────▼────────────────────────────┐
│                     SERVICE LAYER                      │
│ AuthService | BookingService | AdminService           │
│ - Business rules & input validations                   │
│ - ACID Transactions & Row-level locking (`FOR UPDATE`)  │
│ - Role authorization (USER vs ADMIN)                   │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                       DAO LAYER                        │
│ UserDAO | TrainDAO | BookingDAO | PassengerDAO        │
│ - PreparedStatement queries (SQL Injection Immune)     │
│ - Try-with-resources JDBC Connection Management        │
└───────────────────────────┬────────────────────────────┘
                            │
┌───────────────────────────▼────────────────────────────┐
│                    DATABASE (MySQL)                    │
│ users | trains | train_seats_availability              │
│ bookings | passengers                                  │
└────────────────────────────────────────────────────────┘
```

---

## 2. Project Directory Structure

```
Revervation/
├── pom.xml                               # Maven project descriptor
├── railway_reservation.sql               # Complete MySQL schema & seed data
├── README.md                             # Comprehensive project documentation
├── run.bat                               # Windows one-click command-line runner
├── .project                              # Eclipse project descriptor
├── .classpath                            # Eclipse build path descriptor
├── .gitignore                            # Version control exclusions
├── .settings/
│   └── org.eclipse.jdt.core.prefs        # Eclipse Java 17+ compiler settings
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/railway/
│   │   │       ├── RailwayApp.java               # Main Desktop Entry Point
│   │   │       ├── config/
│   │   │       │   └── DatabaseConnection.java   # JDBC Connection & config manager
│   │   │       ├── model/
│   │   │       │   ├── Role.java                 # Enum: USER, ADMIN
│   │   │       │   ├── BookingStatus.java        # Enum: CONFIRMED, CANCELLED
│   │   │       │   ├── User.java                 # User entity
│   │   │       │   ├── Train.java                # Train & schedule entity
│   │   │       │   ├── Booking.java              # Booking & PNR entity
│   │   │       │   └── Passenger.java            # Passenger entity
│   │   │       ├── dao/
│   │   │       │   ├── UserDAO.java              # User JDBC operations
│   │   │       │   ├── TrainDAO.java             # Train & seat inventory JDBC ops
│   │   │       │   ├── BookingDAO.java           # Booking JDBC operations
│   │   │       │   └── PassengerDAO.java         # Passenger JDBC operations
│   │   │       ├── service/
│   │   │       │   ├── AuthService.java          # Authentication & registration
│   │   │       │   ├── BookingService.java       # Reservation & cancellation transactions
│   │   │       │   └── AdminService.java         # Administrative route oversight
│   │   │       ├── util/
│   │   │       │   ├── PasswordUtil.java         # BCrypt hashing & checking
│   │   │       │   └── ValidationUtil.java       # Input & format validation rules
│   │   │       └── ui/
│   │   │           ├── Theme.java                # Navy-Blue & Teal styling system
│   │   │           ├── LoginFrame.java           # Authentication screen
│   │   │           ├── RegisterFrame.java        # User registration screen
│   │   │           ├── DashboardFrame.java       # User portal & overview
│   │   │           ├── TrainSearchFrame.java     # Train search & live seat checking
│   │   │           ├── BookingFrame.java         # Multi-passenger booking form
│   │   │           ├── MyBookingsFrame.java      # User booking history & cancel
│   │   │           ├── AdminFrame.java           # Admin portal (Trains, Bookings, Stats)
│   │   │           ├── TicketDetailDialog.java   # E-Ticket receipt dialog
│   │   │           └── common/
│   │   │               ├── ModernButton.java     # Custom rounded flat button
│   │   │               ├── ModernTextField.java  # Custom styled text input
│   │   │               ├── ModernPasswordField.java # Custom styled password input
│   │   │               ├── HeaderPanel.java      # Reusable top navigation bar
│   │   │               └── StatusBadgeRenderer.java # Table pill renderer
│   │   └── resources/
│   │       ├── db.properties                 # Active database connection config
│   │       └── db.properties.example         # Template database properties
│   └── test/
│       └── java/
│           └── com/railway/
│               ├── ValidationUtilTest.java   # Unit tests for input rules
│               ├── PasswordUtilTest.java     # Unit tests for BCrypt hashing
│               └── ModelTest.java            # Unit tests for domain models
```

---

## 3. Database Setup (`railway_reservation.sql`)

### Database Requirements
- MySQL Server 8.0 or later running on port `3306`.
- Schema Name: `railway_db`.

### How to Import via MySQL Workbench
1. Open **MySQL Workbench** and connect to your local MySQL instance.
2. Go to **File** -> **Open SQL Script...** (or press `Ctrl + Shift + O`).
3. Select the file: `railway_reservation.sql` from this project folder.
4. Click the **Execute** button (lightning bolt icon ⚡) to run the entire script.
5. In the *Schemas* navigator on the left, right-click and choose **Refresh All**. You will see `railway_db` with all 5 tables (`users`, `trains`, `train_seats_availability`, `bookings`, `passengers`) and pre-populated seed data.

### How to Import via MySQL Command Line Client
Open your terminal / Command Prompt and run:
```bash
mysql -u root -p < railway_reservation.sql
```
*(Enter your MySQL root password when prompted).*

---

## 4. Database Configuration

The application never hardcodes database credentials. It resolves credentials with the following priority:

1. **Environment Variables:**
   - `RAILWAY_DB_URL` (e.g. `jdbc:mysql://localhost:3306/railway_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC`)
   - `RAILWAY_DB_USER` (e.g. `root`)
   - `RAILWAY_DB_PASSWORD` (e.g. your MySQL password)

2. **Local Configuration File (`db.properties`):**
   Located in the project root or in `src/main/resources/db.properties`:
   ```properties
   db.url=jdbc:mysql://localhost:3306/railway_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
   db.user=root
   db.password=root
   ```
   *(Update `db.password` to match your local MySQL root password).*

3. **Fallback Defaults:**
   `localhost:3306/railway_db`, user `root`, password `root`.

---

## 5. Pre-Configured Seed Accounts

Passwords are stored strictly as **BCrypt hashes** (cost factor 12) in the database.

| Role | Name | Email | Password |
|---|---|---|---|
| **ADMIN** | System Administrator | `admin@railway.com` | `Admin@123` |
| **USER** | Rahul Sharma | `rahul.sharma@example.com` | `User@123` |
| **USER** | Priya Patel | `priya.patel@example.com` | `User@123` |

---

## 6. Eclipse IDE Setup and Execution Guide

Follow these steps to import and run the project in Eclipse:

### Step 1: Install JDK 17+ and Eclipse IDE
- Download and install **Java Development Kit (JDK) 17 or later** (e.g., Eclipse Temurin JDK 17, 21, or 25).
- Download and install **Eclipse IDE for Java Developers** (includes Maven m2e plugin by default).

### Step 2: Import Project into Eclipse
1. Launch Eclipse and select your preferred workspace.
2. Click **File** -> **Import...**
3. In the Import wizard, expand **Maven** and select **Existing Maven Projects**, then click **Next >**.
4. In **Root Directory**, click **Browse...** and select this project folder:
   `C:\Users\Shivam\OneDrive\Desktop\Revervation`
5. Eclipse will scan and detect `/pom.xml com.railway:railway-reservation-system:1.0.0:jar`.
6. Ensure the checkbox next to `pom.xml` is checked, then click **Finish**.
7. Wait for Eclipse to import and build the project (status visible in bottom right progress bar).

### Step 3: Update Maven Dependencies
1. Right-click the project `railway-reservation-system` in **Package Explorer** / **Project Explorer**.
2. Select **Maven** -> **Update Project...** (or press `Alt + F5`).
3. Check the project, ensure **Force Update of Snapshots/Releases** is checked, and click **OK**.

### Step 4: Configure Database Credentials
- Open `src/main/resources/db.properties`.
- Set `db.user` and `db.password` to match your local MySQL instance.

### Step 5: Run the Desktop Application
1. In the **Package Explorer**, expand:
   `src/main/java` -> `com.railway` -> `RailwayApp.java`
2. Right-click `RailwayApp.java`.
3. Choose **Run As** -> **Java Application**.
4. The Indian Railways desktop login screen will launch on your desktop.

### Step 6: Run Unit Tests in Eclipse
1. In **Package Explorer**, expand `src/test/java`.
2. Right-click `src/test/java` or any test class (`ValidationUtilTest.java`, `PasswordUtilTest.java`, `ModelTest.java`).
3. Choose **Run As** -> **JUnit Test**.
4. All test cases will pass with a green bar.

---

## 7. Command Line Execution (Without Eclipse)

### Option A: Using the Windows Batch Launcher
Double-click `run.bat` or run in Command Prompt:
```cmd
run.bat
```

### Option B: Using Maven
```bash
mvn clean compile
mvn exec:java
```

To run unit tests via Maven:
```bash
mvn test
```

---

## 8. Application Modules Walkthrough

### Module A: Login and Registration
- **Login Window:**
  - Modern split-card layout with railway branding on the left and login form on the right.
  - Role-based automatic dispatch:
    - Users logging in as `ADMIN` are routed to the **AdminFrame**.
    - Users logging in as `USER` are routed to the **DashboardFrame**.
  - Password input masked; verified against BCrypt hash in `users` table.
  - "Check Database Status" button displays real-time connection diagnostics.
- **Registration Window:**
  - Fields: Full Name, Email, Phone, Role (User / Admin), Password, Confirm Password.
  - Real-time validations: Email format regex, 10-15 digit phone, password minimum 6 characters, matching passwords.
  - Duplicate email check prevents duplicate registrations.
  - Hashes password with BCrypt before storage.

### Module B: User Dashboard
- **Welcome Banner:** Greets the authenticated user by name.
- **Metric Cards:** Displays Total Bookings, Confirmed Tickets, and Cancelled Tickets for the user.
- **Recent Bookings Table:** Shows the user's latest bookings with color-coded status badges.
- **Quick Action Buttons:**
  - `🔍 Search & Book Trains`: opens Train Search.
  - `❌ Cancel by PNR`: prompts for PNR and cancels ticket immediately.
  - `📄 View Ticket Details`: opens the formatted e-ticket receipt modal.

### Module C: Train Search
- Search by Source Station, Destination Station, and Journey Date.
- Dropdown combos auto-populated with all unique stations currently in the database.
- Quick "⇄ Swap" button swaps source and destination with one click.
- Validations:
  - Source and Destination cannot be identical.
  - Journey date cannot be in the past.
- **Search Results JTable:**
  - Displays Train Number, Train Name, Route, Departure Time, Arrival Time, Base Fare, and **live Available Seats** for that specific date.
  - Visual seat indicator: shows `AVAILABLE` or `SOLD OUT`.
  - Double-click or click **"Book Selected Train ➔"** to proceed to booking.

### Module D: Ticket Booking (ACID Transactions & Overbooking Prevention)
- Selected train banner displays route, timings, journey date, base fare, and remaining capacity.
- Dynamic passenger form supports adding 1 to 6 passengers per booking:
  - Passenger Name, Age (1-120), Gender (Male/Female/Other), Berth Preference (Lower, Middle, Upper, Side Lower, Side Upper).
  - Add / Remove passenger buttons.
- Real-time fare calculation: automatically updates `Passenger Count x Base Fare = Total Fare`.
- **Concurrency & Overbooking Protection:**
  - Uses `Connection.setAutoCommit(false)` to start a database transaction.
  - Queries `train_seats_availability` with `SELECT ... FOR UPDATE` to obtain a pessimistic lock on the seat inventory row for `(train_id, journey_date)`.
  - Atomically verifies `available_seats >= passenger_count`. If insufficient, triggers `conn.rollback()` and displays an alert.
  - Atomically decrements `available_seats` with a constraint check (`available_seats >= 0`).
  - Generates unique PNR (`PNR` + 8 digits) and inserts booking record.
  - Allocates coaches and seats (`S1-1`, `S1-2`, etc.) and inserts passenger records.
  - Commits transaction (`conn.commit()`).
  - On any error, executes `conn.rollback()`.

### Module E: My Bookings
- Lists all ticket reservations made by the logged-in user.
- Search filter: filter by PNR substring or by Status (`CONFIRMED`, `CANCELLED`).
- **View Ticket Receipt:** Opens the `TicketDetailDialog` with full passenger roster, seat assignments, and print option.
- **Cancel Ticket:** Allows users to cancel their confirmed bookings with confirmation prompt.

### Module F: Ticket Cancellation
- Verifies that the ticket belongs to the logged-in user (prevents unauthorized cancellation of another user's ticket).
- Locks booking record `FOR UPDATE`.
- Rejects repeated cancellations if the ticket is already `CANCELLED`.
- Updates booking status to `CANCELLED`.
- Safely restores seats in `train_seats_availability` (`available_seats = LEAST(total_seats, available_seats + passenger_count)`).
- Full transaction rollback on failure.

### Module G: Admin Control Panel
Protected by `admin.isAdmin()` role verification in both UI and Service layers:
- **Tab 1: System Overview & Analytics:**
  - Metric cards: Total Trains, Active Routes, Registered Passengers, Total Bookings, Confirmed Tickets, Cancelled Tickets, Total System Revenue.
- **Tab 2: Train & Route Management:**
  - Form to register new train routes (Train Number, Name, Source, Destination, Departure Time, Arrival Time, Fare, Seat Capacity).
  - JTable listing all trains in the system.
  - "Toggle Active / Inactive" button to enable/disable train routes.
  - "Delete Train" button (with foreign key checks).
- **Tab 3: Bookings Oversight:**
  - Search customer bookings across the entire database by PNR, Customer Email, Train Number, or Journey Date.
  - View full ticket details and passenger roster for any customer.
  - Administrative cancellation button to cancel bookings and release inventory.

---

## 9. Test Cases and Expected Results

| # | Test Scenario | Input / Action | Expected Result |
|---|---|---|---|
| **TC-01** | Successful Login (User) | `rahul.sharma@example.com` / `User@123` | Authentication succeeds; opens `DashboardFrame`. |
| **TC-02** | Successful Login (Admin) | `admin@railway.com` / `Admin@123` | Authentication succeeds; opens `AdminFrame`. |
| **TC-03** | Failed Login (Invalid Password) | `admin@railway.com` / `WrongPass` | Rejection message: "Invalid email or password." |
| **TC-04** | User Registration | New valid email, name, phone, password | Account created in DB with BCrypt hash; redirects to login. |
| **TC-05** | Duplicate Email Registration | Existing email `rahul.sharma@example.com` | Blocked with "An account with this email address already exists." |
| **TC-06** | Train Search (Valid Route) | From: "New Delhi", To: "Mumbai Central", Today | Displays Train 12952 (Mumbai Rajdhani) with available seats. |
| **TC-07** | Train Search (Invalid Route) | From: "New Delhi", To: "New Delhi" | Blocked: "Source and Destination stations cannot be identical." |
| **TC-08** | Train Search (Past Date) | Date: Yesterday (`2026-10-27`) | Blocked: "Journey date cannot be in the past." |
| **TC-09** | Successful Multi-Passenger Booking | Train 12952, Date: Tomorrow, 2 passengers | Transaction commits; unique PNR generated; seats allocated; seats decremented in DB. |
| **TC-10** | Insufficient Seats / Overbooking | Attempt booking 150 seats when only 10 remain | Transaction rolls back; displays "Insufficient seats available. Only 10 seat(s) remaining." |
| **TC-11** | Successful Ticket Cancellation | Cancel confirmed PNR belonging to logged-in user | Status set to `CANCELLED`; seats restored to train availability table. |
| **TC-12** | Repeated Ticket Cancellation | Cancel an already cancelled PNR | Blocked: "Ticket with PNR ... is already cancelled." |
| **TC-13** | Unauthorized Cancellation | User B attempts cancelling User A's PNR | Blocked: "Unauthorized: You can only cancel your own bookings." |
| **TC-14** | Admin Access Protection | Normal user tries accessing AdminFrame | Access denied; operation blocked by `enforceAdmin()` in service. |
| **TC-15** | Add Train Schedule (Admin) | Valid train number, name, times, fare, capacity | Train added to `trains` table and visible in search. |

---

## 10. Troubleshooting Guide

### 1. `CommunicationsException: Communications link failure`
- **Cause:** MySQL Server is not running or port 3306 is blocked.
- **Solution:**
  - On Windows, open **Services** (`services.msc`), find **MySQL80** (or **MySQL**), right-click and click **Start**.
  - Or run in administrator PowerShell: `net start MySQL80`.

### 2. `Access denied for user 'root'@'localhost'`
- **Cause:** Incorrect MySQL password in configuration.
- **Solution:** Open `src/main/resources/db.properties` and update `db.password` with your real MySQL password. Alternatively, set the environment variable:
  ```cmd
  set RAILWAY_DB_PASSWORD=your_actual_password
  ```

### 3. `Public Key Retrieval is not allowed`
- **Cause:** MySQL 8 uses `caching_sha2_password` authentication by default.
- **Solution:** This is already solved in `db.properties` by including `allowPublicKeyRetrieval=true&useSSL=false` in the JDBC connection URL.

### 4. `Table 'railway_db.users' doesn't exist`
- **Cause:** Database script has not yet been executed in MySQL.
- **Solution:** Execute `railway_reservation.sql` in MySQL Workbench or run:
  ```cmd
  mysql -u root -p < railway_reservation.sql
  ```

### 5. Eclipse: `Project configuration is not up-to-date with pom.xml`
- **Solution:** Right-click project -> **Maven** -> **Update Project...** -> Check **Force Update** -> Click **OK**.

---

## 11. Final Implementation Checklist

- [x] Java 17+ compatible source code.
- [x] Complete Maven `pom.xml` with MySQL Connector/J, jBCrypt, and JUnit 5.
- [x] MySQL schema script `railway_reservation.sql` with tables, indexes, constraints, and seed data.
- [x] BCrypt password hashing (never plain-text passwords).
- [x] Role-based authentication (Admin and User).
- [x] User Dashboard with statistics and quick actions.
- [x] Train Search with live seat availability by journey date.
- [x] Multi-passenger ticket booking with automatic fare calculation.
- [x] Concurrency-safe transactions with row locking (`SELECT ... FOR UPDATE`) to prevent overbooking.
- [x] Unique PNR generation and e-ticket receipt modal.
- [x] My Bookings screen with filter and ticket details.
- [x] Cancellation module with ownership verification, repeated cancellation prevention, and atomic seat restoring.
- [x] Admin Control Panel with statistics, train CRUD/toggle, and bookings search.
- [x] Non-blocking GUI using `SwingWorker` for background database operations.
- [x] PreparedStatement used for all SQL queries (immune to SQL injection).
- [x] Eclipse `.project`, `.classpath`, and `.settings` included.
- [x] Unit test suite passing with 100% success rate.

