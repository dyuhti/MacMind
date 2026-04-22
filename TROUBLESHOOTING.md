# 🔧 Troubleshooting Guide

## ❌ Problem: "Connection refused" when clicking Save

**Cause:** Backend server not running

**Solution:**
1. Open terminal
2. Run: `cd C:\Users\Dyuthi\med_calci_app\backend && python run.py`
3. Wait for "Running on http://127.0.0.1:5000"
4. Try saving again

---

## ❌ Problem: "No cases yet" when viewing history

**Cause:** Either no cases saved or API not responding

**Solution:**
1. In app: Click "Save Case" button on Results screen
2. Check backend terminal for: `✅ Case saved with ID: X`
3. Refresh by pulling down on Cases List
4. Try viewing history again

---

## ❌ Problem: Save button shows error message

**Possible Causes & Solutions:**

### "Network error: connection refused"
- Backend not running → Start it with `python run.py`
- Wrong URL in API config → Should be `10.0.2.2:5000` for emulator
- Emulator not able to reach host → Restart emulator

### "Failed to save case"  
- Missing required fields → Fill all form fields
- Database error → Check MySQL is running
- Check backend logs for error message

### "Unexpected status code"
- API endpoint wrong → Should be `/api/calculator/cases`
- Verify in backend that endpoint exists

---

## ❌ Problem: "Unknown column 'X' in field list"

**Cause:** Using wrong API endpoint (cases.py instead of calculator.py)

**Solution:**
- Already fixed! Case service now uses `/api/calculator/cases`
- Make sure you're using latest code

---

## ❌ Problem: Cases list is empty but I saved cases

**Possible Causes & Solutions:**

### Backend started later than app
- Close and reopen app
- Tap refresh button (↻) on cases list

### Database doesn't have data
Run this in MySQL:
```bash
mysql -u root -proot123 med_calci_app -e "SELECT COUNT(*) FROM cases;"
```
Should show `count(*) > 0`

### Wrong database
Check in backend logs:
```
Database: ??? med_calci_app
```
Should say `med_calci_app`

---

## ❌ Problem: Can't connect to MySQL

**Cause:** MySQL service not running or wrong credentials

**Solution:**
1. Check MySQL is running:
   ```bash
   mysql -u root -p
   ```
2. Enter password: `root123`
3. If it fails, restart MySQL service

---

## ✅ Verify Everything is Working

### Quick Check (30 seconds)

1. **Backend running?**
   ```bash
   curl http://127.0.0.1:5000/api/calculator/cases
   ```
   Should return JSON array

2. **MySQL working?**
   ```bash
   mysql -u root -proot123 med_calci_app -e "SELECT COUNT(*) FROM cases;"
   ```
   Should show count

3. **Flutter can reach backend?**
   In Flutter logs, when you click Save, you should see:
   ```
   📝 Save Case Request: http://10.0.2.2:5000/api/calculator/cases
   📤 Request Body: {...}
   📩 Save Case Response Status: 201
   ```

### If All Checks Pass
✅ Everything is working! Try the full flow

---

## 🔍 Debug Tips

### 1. Check Backend Logs
When you click Save in Flutter, you should see in terminal:
```
💾 Saving case: John Doe (P123)
✅ Case saved with ID: 5
```

If you don't see this, the request isn't reaching backend.

### 2. Check Flutter Debug Output
Open Flutter DevTools:
```bash
flutter run -d emulator-5554 -v
```

Look for: `📝 Save Case Request:` messages

### 3. Test API Directly
Save test data:
```bash
curl -X POST http://127.0.0.1:5000/api/calculator/cases \
  -H "Content-Type: application/json" \
  -d '{"patient_name":"Test","patient_id":"123","date":"2026-04-22","surgery_type":"test","anesthetic_agent":"Sevoflurane","molecular_mass":"200","vapor_constant":"184","density":"1.5"}'
```

Should return 201 with case ID.

### 4. Test Get All Cases
```bash
curl http://127.0.0.1:5000/api/calculator/cases
```

Should return array of cases.

---

## 🆘 Still Not Working?

### Step 1: Check Logs
Collect these logs:
1. Flutter console output when clicking Save
2. Backend terminal output
3. MySQL error (if any)

### Step 2: Verify Setup
Run test script:
```bash
cd C:\Users\Dyuthi\med_calci_app\backend
python test_complete_flow.py
```

All tests should pass.

### Step 3: Restart Everything
1. Kill backend: Press CTRL+C in backend terminal
2. Kill Flutter app: Press Q in Flutter terminal
3. Restart backend: `python run.py`
4. Restart Flutter: `flutter run -d emulator-5554`

### Step 4: Check Credentials
Backend needs:
- MySQL Host: localhost
- User: root  
- Password: root123
- Database: med_calci_app

Check in: `backend/config/config.py`

---

## 📞 Common Error Messages & Fixes

| Error | Fix |
|-------|-----|
| `Connection refused` | Start backend with `python run.py` |
| `No route to host` | Check 10.0.2.2 IP in API config |
| `404 Not Found` | Wrong API endpoint or route not registered |
| `500 Internal Server Error` | Check backend logs for exception |
| `Access denied` | Wrong MySQL password (should be root123) |
| `Unknown database` | Create med_calci_app database |
| `Unknown column` | Using wrong endpoint (/api/cases instead of /api/calculator/cases) |
| `CORS error` | Backend CORS should allow all (*) |

---

## ✨ Performance Tips

1. **Large number of cases?**
   - Pagination not implemented yet
   - For 100+ cases, consider adding pagination

2. **Slow save?**
   - Check MySQL is responsive
   - Ensure no heavy operations running

3. **Slow load?**
   - First load: ~2-3 seconds normal
   - Subsequent: ~1 second

---

## 🎯 Success Indicators

When working correctly, you should see:

✅ **Save Success**
```
📝 Save Case Request: http://10.0.2.2:5000/api/calculator/cases
✅ Case saved successfully
```

✅ **View Success**  
```
📋 Fetch Cases Request: http://10.0.2.2:5000/api/calculator/cases
✅ Retrieved 5 cases
```

✅ **In Terminal**
```
💾 Saving case: John Doe (P123)
✅ Case saved with ID: 5
```

If you see these, everything is working! 🎉
