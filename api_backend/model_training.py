# api_backend/model_training.py

import pandas as pd
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import classification_report, accuracy_score, f1_score
from sklearn.ensemble import GradientBoostingClassifier
import joblib
import os

def train_and_save_model():
    # 1. Veri Yükle
    data_path = os.path.join(os.path.dirname(__file__), '..', 'data', 'processed', 'cleaned_dataset.csv')
    data_path = os.path.abspath(data_path)
    if not os.path.exists(data_path):
        raise FileNotFoundError(f"Veri dosyası bulunamadı: {data_path}")
    df = pd.read_csv(data_path)

    # 2. Kategorik verileri encode et
    df_encoded = df.copy()
    label_encoders = {}
    for col in df_encoded.select_dtypes(include='object').columns:
        le = LabelEncoder()
        df_encoded[col] = le.fit_transform(df_encoded[col])
        label_encoders[col] = le

    # 3. Özellik ve hedef değişkeni ayır
    X = df_encoded.drop('Depression', axis=1)
    y = df_encoded['Depression']

    # 4. Veri setini ayır
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # 5. Ölçekleme
    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_test = scaler.transform(X_test)

    # 6. Model oluştur (GradientBoosting örneği)
    model = GradientBoostingClassifier(learning_rate=0.1, n_estimators=100)
    model.fit(X_train, y_train)

    # 7. Modeli değerlendir
    y_pred = model.predict(X_test)
    print("Accuracy:", accuracy_score(y_test, y_pred))
    print("F1 Score:", f1_score(y_test, y_pred))
    print("Classification Report:\n", classification_report(y_test, y_pred))

    # 8. Modeli ve scaler'ı kaydet
    save_dir = os.path.dirname(__file__)
    model_path = os.path.join(os.getcwd(), "best_model.pkl")
    scaler_path = os.path.join(os.getcwd(), "scaler.pkl")

    joblib.dump(model, model_path)
    joblib.dump(scaler, scaler_path)

    print(f"Model saved to {model_path}")
    print(f"Scaler saved to {scaler_path}")

if __name__ == "__main__":
    train_and_save_model()
