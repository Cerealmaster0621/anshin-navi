import pandas as pd
import json
from pathlib import Path
import os

shelter_data_path = "RawDatas/全国指定緊急避難場所データ.csv"
output_json_path = "AnshinNavi/Datas/shelters.json"

def convert_csv_to_json():
    if not os.path.exists(shelter_data_path):
        raise FileNotFoundError(f"CSV file not found at: {shelter_data_path}")
    
    # Read CSV file
    df = pd.read_csv(shelter_data_path, encoding='utf-8')
    
    # Create list to store shelter objects
    shelters = []
    
    # Convert each row to a shelter object
    for _, row in df.iterrows():
        shelter = {
            "id": str(uuid.uuid4()),
            "regionCode": str(row['市町村コード']),
            "regionName": str(row['都道府県名及び市町村名']),
            "number": str(row['NO']),
            "name": str(row['施設・場所名']),
            "address": str(row['住所']),
            "generalFlooding": bool(row['洪水']),
            "landslide": bool(row['崖崩れ、土石流及び地滑り']),
            "highTide": bool(row['高潮']),
            "earthquake": bool(row['地震']),
            "tsunami": bool(row['津波']),
            "fire": bool(row['大規模な火事']),
            "internalFlooding": bool(row['内水氾濫']),
            "volcano": bool(row['火山現象']),
            "isSameAsEvacuationCenter": bool(row['指定避難所との住所同一']),
            "latitude": float(row['緯度']),
            "longitude": float(row['経度']),
            "additionalInfo": str(row.get('備考', ''))
        }
        shelters.append(shelter)
    
    # Create directory if it doesn't exist
    output_path = Path(output_json_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Write to JSON file
    with open(output_json_path, 'w', encoding='utf-8') as f:
        json.dump({"shelters": shelters}, f, ensure_ascii=False, indent=2)
    
    print(f"Successfully converted {len(shelters)} shelters to JSON")

if __name__ == "__main__":
    import uuid
    try:
        convert_csv_to_json()
    except Exception as e:
        print(f"Error converting CSV to JSON: {str(e)}")
