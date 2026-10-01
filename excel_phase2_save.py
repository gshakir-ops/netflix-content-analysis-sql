import openpyxl
import os

xlsm_path = r"C:\Users\LENOVO\Desktop\Excel Project\excel project 1.xlsm"

print("=" * 60)
print("SAVING WORKBOOK")
print("=" * 60)

# Load and save
wb = openpyxl.load_workbook(xlsm_path)

# Make sure CSV directory exists
csv_dir = r"C:\Users\LENOVO\Desktop\Excel Project\data"
os.makedirs(csv_dir, exist_ok=True)

# Save workbook
wb.save(xlsm_path)
print(f"\n✓ Workbook saved: {xlsm_path}")
print(f"  Modified: {os.path.getmtime(xlsm_path)}")

# Verify CSV exists
csv_path = f"{csv_dir}\\expense_dataset.csv"
if os.path.exists(csv_path):
    file_size = os.path.getsize(csv_path)
    lines = sum(1 for line in open(csv_path))
    print(f"\n✓ CSV file verified: {csv_path}")
    print(f"  Size: {file_size / 1024:.2f} KB")
    print(f"  Lines: {lines}")
else:
    print(f"\n✗ CSV file NOT found: {csv_path}")

print("\n" + "=" * 60)
print("PHASE 2 COMPLETE")
print("=" * 60)
