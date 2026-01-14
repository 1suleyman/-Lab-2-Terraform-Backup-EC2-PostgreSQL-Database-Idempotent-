# 🧱 Lab 2 (Terraform) — Backup EC2 PostgreSQL Database (Idempotent)

In this lab, I refactored the **manual PostgreSQL backup workflow** from Lab 2 into a **repeatable, idempotent Terraform-based implementation** using **EC2 user data**.

The goal was to understand **what can and cannot be automated safely with Terraform**, how **user data behaves**, and how to design a **first-boot backup workflow** that is predictable, debuggable, and production-aware.

---

## 📋 Lab Overview

**Goal:**

* Convert the manual PostgreSQL backup process into Terraform
* Automate backup creation using `user_data.sh`
* Ensure backups are created only after PostgreSQL is ready
* Avoid overwriting backups by using timestamped filenames
* Verify backup creation and format post-deployment
* Understand Terraform + user data limitations

**Learning Outcomes:**

* Understand **Terraform idempotency vs runtime operations**
* Learn how **EC2 user data executes (first boot only)**
* Automate `pg_dump` safely from inside Docker
* Store backups on the EC2 host filesystem
* Debug binary stream issues (`-t` vs `-i`)
* Know when **Terraform is the wrong tool** for recurring backups

---

## 🛠 Step-by-Step Journey

### Step 1: Design the Terraform-Compatible Backup Plan

The original manual steps were:

1. Verify EC2 disk space
2. Inspect Docker disk usage
3. Create a backup directory on the EC2 host
4. Create a compressed PostgreSQL dump from Docker
5. Store the dump outside the container
6. Verify backup existence and format

**Key question:**
➡️ *Can this be done safely with Terraform?*

---

### Step 2: Understand Terraform + `user_data` Realities

Before implementing, several **important constraints** were identified:

#### 1️⃣ `user_data` Runs Once

* Executes **only on first boot**
* Re-running `terraform apply` does **not** re-run backups
* Backups via `user_data` are suitable for:

  * Initial provisioning
  * First-run validation
* ❌ Not suitable for scheduled or recurring backups

---

#### 2️⃣ Backup Lives on EC2 Disk

* Dump file is written to:

```text
/home/ec2-user/db_backups/
```

* If the EC2 instance is terminated:

  * Backup is lost unless:

    * EBS volume is retained
    * Snapshot is taken
    * Backup is uploaded to S3 (recommended for production)

---

#### 3️⃣ PostgreSQL Must Be Ready First

* Backup must run **after**:

  * Docker starts
  * PostgreSQL container is healthy
  * Schema and seed data are applied

📌 Backup commands were placed **after readiness + seed logic** in `user_data.sh`.

---

### Step 3: Improve Backup Safety (Timestamped Files)

Instead of overwriting:

```text
appdb.dump
```

The backup file now uses timestamps:

```text
appdb-YYYY-MM-DD-HHMMSS.dump
```

**Benefits:**

* Prevents accidental overwrites
* Enables backup history
* Makes validation and debugging easier

---

### Step 4: Apply Terraform Configuration

**Commands:**

```bash
terraform init
terraform plan
terraform apply
```

* Confirmed with `yes`
* EC2 instance launched
* `user_data.sh` executed on first boot
* Backup created automatically

---

### Step 5: Verify Backup File Creation

After SSHing into the EC2 instance:

```bash
ls -lah ~/db_backups
```

**Observed output:**

* Timestamped `.dump` file
* Non-trivial size (~3.9 KB)
* Owned by `ec2-user`

📌 This confirms:

* Backup directory exists
* Backup file was created successfully
* File permissions are correct

---

### Step 6: Validate Backup Format (Correct Scope)

**Command:**

```bash
file ~/db_backups/appdb-<timestamp>.dump
```

**Result:**

```
PostgreSQL custom database dump - v1.14-0
```

✅ Confirms the file is a valid PostgreSQL custom-format backup.

---

## 🧠 Debugging Insight: `-t` vs `-i` in `docker exec`

During validation attempts, a key issue surfaced:

### ❌ Problem

Using:

```bash
docker exec -t postgres_db pg_dump ...
```

Caused binary output issues when redirecting to a file.

### ✅ Fix

Use **stdin mode** instead:

```bash
docker exec -i postgres_db pg_dump ...
```

### 📌 Rule of Thumb

| Flag | Use Case                       |
| ---- | ------------------------------ |
| `-t` | Interactive terminals          |
| `-i` | Streaming data / binary output |

🚨 **Never use `-t` for binary dumps (`-Fc`)**

---

## ⚠️ Important Scope Correction

At one point, I attempted to:

* Run `pg_restore -l`
* Inspect dump contents
* Validate restore logic

📌 **Reality check:**
This lab’s objective was **backup creation**, not restore testing.

Once the following were confirmed, the lab was complete:

* Backup file exists
* File size is non-zero
* File is recognized as PostgreSQL custom format

➡️ Anything beyond that belongs in a **restore lab**, not here.

---

## 🧹 Cleanup

To avoid ongoing costs:

```bash
terraform destroy
```

* Confirmed with `yes`
* EC2 instance terminated
* Infrastructure fully cleaned up

---

## ✅ Key Commands Summary

| Task                   | Command                        |
| ---------------------- | ------------------------------ |
| Initialize Terraform   | `terraform init`               |
| Apply infrastructure   | `terraform apply`              |
| SSH into EC2           | `ssh -i key.pem ec2-user@<ip>` |
| List backup files      | `ls -lah ~/db_backups`         |
| Validate dump format   | `file appdb-*.dump`            |
| Destroy infrastructure | `terraform destroy`            |

---

## 📌 Lab Summary

| Area                             | Result |
| -------------------------------- | ------ |
| Manual backup refactored         | ✅      |
| Terraform idempotency understood | ✅      |
| Backup automated via user data   | ✅      |
| Timestamped backups implemented  | ✅      |
| Binary stream issue debugged     | ✅      |
| Scope discipline reinforced      | ✅      |
| Resources cleaned up             | ✅      |

---

## ⚡ Takeaway

This lab reinforced a **critical DevOps lesson**:

> **Terraform provisions infrastructure — it is not a job runner.**

Using Terraform for:

* First-boot automation → ✅
* Infrastructure state → ✅
* Recurring operational tasks → ❌

For production-grade backups, the next evolution would be:

* S3 uploads
* Lifecycle policies
* Cron or EventBridge
* Or managed database backups (Aurora)
