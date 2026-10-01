import openpyxl
from openpyxl.utils import get_column_letter
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from datetime import datetime
import csv

xlsm_path = r"C:\Users\LENOVO\Desktop\Excel Project\excel project 1.xlsm"

# Load workbook
wb = openpyxl.load_workbook(xlsm_path, data_only=False)

print("=" * 60)
print("PHASE 2 WORKBOOK IMPROVEMENTS - COMPREHENSIVE ANALYSIS")
print("=" * 60)

# ===== TASK 1: VERIFY INSIGHTS SHEET =====
print("\n[TASK 1] VERIFY INSIGHTS SHEET")
print("-" * 60)

if "Insights" in wb.sheetnames:
    insights_ws = wb["Insights"]
    print("✓ Insights sheet EXISTS")
    print(f"  Dimensions: {insights_ws.dimensions}")
    
    # Check structure
    title = insights_ws['A1'].value
    print(f"  Title (A1): {title}")
    
    # Check for key sections
    sections_found = []
    for row in range(1, insights_ws.max_row + 1):
        cell_val = insights_ws.cell(row, 1).value
        if cell_val and isinstance(cell_val, str):
            if 'SUMMARY' in cell_val.upper() or 'METRICS' in cell_val.upper() or 'FINDINGS' in cell_val.upper():
                sections_found.append(f"Row {row}: {cell_val}")
    
    print(f"  Key sections found: {len(sections_found)}")
    for section in sections_found[:5]:
        print(f"    {section}")
else:
    print("✗ Insights sheet DOES NOT EXIST")

# ===== TASK 2: AUDIT DASHBOARD =====
print("\n[TASK 2] AUDIT DASHBOARD KPIs")
print("-" * 60)

dashboard_ws = wb["Dashboard"]
print(f"✓ Dashboard sheet exists")
print(f"  Dimensions: {dashboard_ws.dimensions}")

# Look for cells with content (especially formulas)
kpi_cells = []
formula_cells = []
for row in range(1, 30):
    for col in range(1, 33):  # A-AF
        cell = dashboard_ws.cell(row, col)
        if cell.value:
            if isinstance(cell.value, str) and cell.value.startswith('='):
                formula_cells.append({
                    'coord': cell.coordinate,
                    'formula': cell.value[:80]
                })
            else:
                kpi_cells.append({
                    'coord': cell.coordinate,
                    'value': str(cell.value)[:40]
                })

print(f"\n  Cells with formulas: {len(formula_cells)}")
if formula_cells:
    for item in formula_cells[:5]:
        print(f"    {item['coord']}: {item['formula']}")

print(f"\n  Cells with static content: {len(kpi_cells)}")
if kpi_cells:
    for item in kpi_cells[:5]:
        print(f"    {item['coord']}: {item['value']}")

# Check for charts
print(f"\n  Chart sheets linked to Dashboard:")
for sheet_name in ['Chart1', 'Chart2', 'Chart3']:
    if sheet_name in wb.sheetnames:
        print(f"    ✓ {sheet_name}")

# ===== TASK 3: VERIFY CALCULATIONS =====
print("\n[TASK 3] VERIFY KEY CALCULATIONS")
print("-" * 60)

data_ws = wb["Data"]
print(f"Data sheet analysis:")
print(f"  Total rows: {data_ws.max_row} (including header)")
print(f"  Data rows: {data_ws.max_row - 1}")
print(f"  Columns: {data_ws.max_column}")

# Read all data for calculations
amounts = []
approved_count = 0
total_approved = 0
departments = {}
vendors = set()

for row in range(2, data_ws.max_row + 1):
    # Amount (column F)
    amount = data_ws.cell(row, 6).value
    if isinstance(amount, (int, float)):
        amounts.append(amount)
    
    # Approved status (column I)
    approved = data_ws.cell(row, 8).value
    if approved == 'Yes':
        approved_count += 1
        if isinstance(amount, (int, float)):
            total_approved += amount
    
    # Department (column C)
    dept = data_ws.cell(row, 3).value
    if dept:
        departments[dept] = departments.get(dept, 0) + (amount if isinstance(amount, (int, float)) else 0)
    
    # Vendor (column K)
    vendor = data_ws.cell(row, 11).value
    if vendor:
        vendors.add(vendor)

total_expenses = sum(amounts) if amounts else 0
avg_expense = total_expenses / len(amounts) if amounts else 0
approval_rate = (approved_count / (data_ws.max_row - 1)) * 100 if data_ws.max_row > 1 else 0

print(f"\n  ✓ Total Expenses: {total_expenses:,.2f} INR")
print(f"  ✓ Average Expense: {avg_expense:,.2f} INR")
print(f"  ✓ Approval Rate: {approval_rate:.2f}% ({approved_count} of {data_ws.max_row - 1})")
print(f"  ✓ Unique Vendors: {len(vendors)}")

print(f"\n  Department Spending:")
for dept, total in sorted(departments.items(), key=lambda x: x[1], reverse=True):
    pct = (total / total_expenses * 100) if total_expenses > 0 else 0
    print(f"    {dept}: {total:,.2f} INR ({pct:.1f}%)")

# ===== TASK 4: EXPORT CSV =====
print("\n[TASK 4] EXPORT DATASET TO CSV")
print("-" * 60)

csv_dir = r"C:\Users\LENOVO\Desktop\Excel Project\data"
csv_path = f"{csv_dir}\\expense_dataset.csv"

# Create directory if needed
import os
os.makedirs(csv_dir, exist_ok=True)

# Get headers
headers = []
for col in range(1, data_ws.max_column + 1):
    headers.append(data_ws.cell(1, col).value)

# Export to CSV
with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(headers)
    
    # Write data rows
    for row in range(2, data_ws.max_row + 1):
        row_data = []
        for col in range(1, data_ws.max_column + 1):
            cell_val = data_ws.cell(row, col).value
            # Format dates if needed
            if isinstance(cell_val, datetime):
                cell_val = cell_val.strftime('%Y-%m-%d')
            row_data.append(cell_val if cell_val is not None else '')
        writer.writerow(row_data)

print(f"✓ CSV exported successfully")
print(f"  File: {csv_path}")
print(f"  Rows: {data_ws.max_row - 1} data rows + 1 header row")
print(f"  Columns: {data_ws.max_column}")
print(f"  File size: {os.path.getsize(csv_path) / 1024:.2f} KB")

# ===== TASK 5: SUMMARY =====
print("\n[TASK 5] WORKBOOK SUMMARY")
print("-" * 60)

print(f"Workbook: excel project 1.xlsm")
print(f"Sheets: {', '.join(wb.sheetnames)}")
print(f"Data: 415 rows × 13 columns (tblExpenses table)")
print(f"Analyses:")
print(f"  - Total Expenses: {total_expenses:,.2f} INR")
print(f"  - Average Expense: {avg_expense:,.2f} INR")
print(f"  - Approval Rate: {approval_rate:.2f}%")
print(f"  - Unique Vendors: {len(vendors)}")
print(f"  - Departments: {len(departments)}")

print("\n" + "=" * 60)
print("ANALYSIS COMPLETE - Ready to save workbook")
print("=" * 60)

