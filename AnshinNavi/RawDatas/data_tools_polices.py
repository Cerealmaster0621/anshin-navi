import pandas as pd
import json
from pathlib import Path
import os
import uuid
import traceback

# Input paths
HONBU_CSV_PATH = "RawDatas/honbu_with_coord(2024:11:20).csv"
KEISATSUSHO_CSV_PATH = "RawDatas/keisatsusyo_with_coord(2024:11:20).csv"
KOBAN_CSV_PATH = "RawDatas/koban_with_coord(2024:11:20).csv"
OUTPUT_JSON_PATH = "AnshinNavi/Datas/polices.json"

def create_police_object(row, police_type, parent_id=None):
    """Create a standardized police object from a CSV row."""
    try:
        # Different field mappings based on police type
        if police_type == "koban":
            name = str(row['名称'])
            prefecture = str(row['都道府県名'])
            furigana = str(row['交番・駐在所頭名（フリガナ）'])
            phone = str(row['電話番号'])
            postal = str(row['郵便番号'])
            city = str(row['市区町村'])
            gov_code = str(row['全国地方公共団体コード'])
            full_addr = str(row['全体表記'])
            town = str(row['町又は大字以降'])
            remarks = ""
        elif police_type == "keisatsusho":
            name = str(row['名称'])
            prefecture = str(row['都道府県'])
            furigana = str(row['フリガナ']) if 'フリガナ' in row else ""
            phone = str(row['電話番号'])
            postal = str(row['郵便番号'])
            city = str(row['市区町村'])
            gov_code = str(row['全国地方公共団体コード'])
            full_addr = str(row['全体表記'])
            town = str(row['町又は大字以降'])
            remarks = str(row['備考']) if '備考' in row else ""
        else:  # honbu
            name = str(row['名称'])
            prefecture = str(row['都道府県'])
            furigana = ""
            phone = str(row['電話番号'])
            postal = str(row['郵便番号'])
            city = str(row['市区町村'])
            gov_code = str(row['全国地方公共団体コード'])
            full_addr = str(row['全体表記'])
            town = str(row['町又は大字以降'])
            remarks = str(row['備考']) if '備考' in row else ""

        # Handle coordinate fields and trustful flag
        try:
            longitude = float(row['longitude']) if not pd.isna(row['longitude']) else 0.0
            latitude = float(row['latitude']) if not pd.isna(row['latitude']) else 0.0
            is_trustful = not pd.isna(row['isTrustful']) and float(row['isTrustful']) > 0
        except KeyError:
            # Try lowercase field names
            longitude = float(row['Longitude']) if not pd.isna(row['Longitude']) else 0.0
            latitude = float(row['Latitude']) if not pd.isna(row['Latitude']) else 0.0
            is_trustful = not pd.isna(row['isTrustful']) and float(row['isTrustful']) > 0

        return {
            "id": str(uuid.uuid4()),
            "policeType": police_type,
            "name": name,
            "phoneNumber": phone,
            "furigana": furigana,
            "postalCode": postal,
            "prefecture": prefecture,
            "cityTownVillage": city,
            "nationalLocalGovernmentCode": gov_code,
            "fullNotation": full_addr,
            "townOrVillageOnwards": town,
            "remarks": remarks,
            "longitude": longitude,
            "latitude": latitude,
            "isCoordinatesTrustful": is_trustful,
            "parent": parent_id
        }
    except Exception as e:
        raise Exception(f"Error creating police object for {police_type}: {str(e)}")

def process_csv_file(file_path, police_type, parent_map=None):
    """Process a CSV file and return list of police objects."""
    df = pd.read_csv(file_path)
    objects = []
    id_map = {}

    for _, row in df.iterrows():
        parent_id = None
        if police_type == "keisatsusho":
            honbu_name = str(row['警察本部名称'])
            parent_id = parent_map.get(honbu_name)
        elif police_type == "koban":
            keisatsusho_name = str(row['警察署名称'])
            parent_id = parent_map.get(keisatsusho_name)

        obj = create_police_object(row, police_type, parent_id)
        objects.append(obj)
        
        # Store ID mapping for parent relationships
        if police_type == "honbu":
            id_map[str(row['名称'])] = obj['id']
        elif police_type == "keisatsusho":
            id_map[str(row['名称'])] = obj['id']

    return objects, id_map

def convert_csv_to_json():
    """Convert CSV files to JSON."""
    try:
        police_objects = []
        honbu_id_map = {}
        keisatsusho_id_map = {}

        # Process honbu first
        if os.path.exists(HONBU_CSV_PATH):
            honbu_objects, honbu_id_map = process_csv_file(
                HONBU_CSV_PATH, "honbu")
            police_objects.extend(honbu_objects)
            print(f"Processed {len(honbu_objects)} honbu records")

        # Process keisatsusho next
        if os.path.exists(KEISATSUSHO_CSV_PATH):
            keisatsusho_objects, keisatsusho_id_map = process_csv_file(
                KEISATSUSHO_CSV_PATH, "keisatsusho", honbu_id_map)
            police_objects.extend(keisatsusho_objects)
            print(f"Processed {len(keisatsusho_objects)} keisatsusho records")

        # Process koban
        if os.path.exists(KOBAN_CSV_PATH):
            koban_objects, _ = process_csv_file(
                KOBAN_CSV_PATH, "koban", keisatsusho_id_map)
            police_objects.extend(koban_objects)
            print(f"Processed {len(koban_objects)} koban records")

        # Create output directory
        output_path = Path(OUTPUT_JSON_PATH)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        # Write JSON file
        with open(OUTPUT_JSON_PATH, 'w', encoding='utf-8') as f:
            json.dump({"polices": police_objects}, f, ensure_ascii=False, indent=2)

        print(f"Successfully created JSON with {len(police_objects)} total records")
        print(f"Output written to: {OUTPUT_JSON_PATH}")

    except Exception as e:
        print(f"Error in convert_csv_to_json:")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        print("Traceback:")
        print(traceback.format_exc())
        raise

if __name__ == "__main__":
    try:
        convert_csv_to_json()
    except Exception as e:
        print("Script execution failed")
        print(f"Final error: {str(e)}")
