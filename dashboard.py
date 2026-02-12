import streamlit as st
import pandas as pd
import numpy as np
import time

from sklearn.linear_model import LinearRegression


# ================== PAGE SETUP ==================

st.set_page_config(
    page_title="Insulin Monitoring Dashboard",
    layout="wide"
)

st.title("💉 Smart Insulin Storage Monitoring System")


# ================== LOAD DATA ==================

@st.cache_data(ttl=5)
def load_data():
    return pd.read_csv("insulin_data.csv")


data = load_data()


# ================== TRAIN MODEL ==================

X = data[['Time','AmbientTemp','Battery']]
y = data['ChamberTemp']

model = LinearRegression()
model.fit(X, y)


# ================== LATEST VALUES ==================

latest = data.iloc[-1]

time_now = latest['Time']
room = latest['AmbientTemp']
chamber = latest['ChamberTemp']
battery = latest['Battery']


# ================== AI PREDICTION ==================

X_latest = pd.DataFrame(
    [[time_now, room, battery]],
    columns=['Time','AmbientTemp','Battery']
)

predicted = model.predict(X_latest)[0]


# ================== STATUS ==================

if predicted > 8:
    status = "🚨 DANGER: Overheating"
    color = "red"

elif predicted < 2:
    status = "❄️ FREEZING RISK"
    color = "blue"

else:
    status = "✅ SAFE"
    color = "green"


# ================== DISPLAY METRICS ==================

col1, col2, col3, col4 = st.columns(4)

col1.metric("Chamber Temp (°C)", f"{chamber:.2f}")
col2.metric("Ambient Temp (°C)", f"{room:.1f}")
col3.metric("Battery (%)", f"{battery:.1f}")
col4.metric("Predicted Temp (°C)", f"{predicted:.2f}")


# ================== STATUS ==================

st.markdown(
    f"<h2 style='color:{color}; text-align:center;'>{status}</h2>",
    unsafe_allow_html=True
)


# ================== GRAPHS ==================

st.subheader("📊 Live Sensor Data")

st.line_chart(
    data[['ChamberTemp','AmbientTemp']]
)


st.subheader("🔋 Battery Level")

st.line_chart(
    data[['Battery']]
)


# ================== AUTO REFRESH ==================

time.sleep(5)
st.rerun()
