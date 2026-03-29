import pandas as pd
from sqlalchemy import create_engine



archivo_csv = "customer_churn_business_dataset.csv"

df = pd.read_csv(archivo_csv)

df['complaint_type'] = df['complaint_type'].fillna('No Complaint')


mapeo_booleano = {'Yes': True, 'No': False}

df['discount_applied'] = df['discount_applied'].map(mapeo_booleano)
df['price_increase_last_3m'] = df['price_increase_last_3m'].map(mapeo_booleano)

# Clientes
cols_clientes = ['customer_id', 'age', 'gender', 'country', 'city', 'customer_segment', 'signup_channel']
dim_clientes = df[cols_clientes].copy()

#Suscripciones
cols_suscripciones = ['customer_id', 'contract_type', 'tenure_months', 'monthly_fee', 'total_revenue', 
                      'payment_method', 'discount_applied', 'price_increase_last_3m']
dim_suscripciones = df[cols_suscripciones].copy()

# Fact Table de Comportamiento (Todo lo demas tiene customer_id como Foreign Key)
cols_usadas = set(cols_clientes + cols_suscripciones)
cols_comportamiento = ['customer_id'] + [col for col in df.columns if col not in cols_usadas]

fact_comportamiento = df[cols_comportamiento].copy()

print(f"Dimensiones creadas:")
print(f"Clientes: {dim_clientes.shape}")
print(f"Suscripciones: {dim_suscripciones.shape}")
print(f"Comportamiento: {fact_comportamiento.shape}")

# Creamos la conexión a la base de datos local
engine = create_engine('mysql+pymysql://saas_user:root@localhost:3306/saas_db')

print("Conectando a la base de datos y cargando tablas...")

# Subimos la Dimensión de Clientes
dim_clientes.to_sql(name='dim_clientes', con=engine, if_exists='replace', index=False)

# Subimos la Dimensión de Suscripciones
dim_suscripciones.to_sql(name='dim_suscripciones', con=engine, if_exists='replace', index=False)

# Subimos la Fact Table de Comportamiento
fact_comportamiento.to_sql(name='fact_comportamiento', con=engine, if_exists='replace', index=False)

print("¡ETL completado con éxito! Los datos están listos para ser consultados.")