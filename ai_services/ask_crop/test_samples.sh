# Test samples for ask_crop service
# Run the service first: uvicorn ask_crop:app --host 0.0.0.0 --port 8001 --reload

# TEST 1: Mango - poor soil
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 20, "P": 15, "K": 10, "ph": 5.0, "humidity": 45.0, "electrical_conductivity": 0.3, "plant": "mango"}'

# TEST 2: Rice - ideal soil
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 90, "P": 42, "K": 43, "ph": 6.5, "humidity": 82.0, "electrical_conductivity": 0.5, "plant": "rice"}'

# TEST 3: Coffee - excess nitrogen
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 140, "P": 28, "K": 25, "ph": 6.8, "humidity": 65.0, "electrical_conductivity": 1.2, "plant": "coffee"}'

# TEST 4: Banana - wrong pH
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 100, "P": 82, "K": 50, "ph": 4.0, "humidity": 78.0, "electrical_conductivity": 0.6, "plant": "banana"}'

# TEST 5: Cotton - dry soil
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 118, "P": 48, "K": 20, "ph": 6.5, "humidity": 20.0, "electrical_conductivity": 0.8, "plant": "cotton"}'

# TEST 6: Grapes - nearly ideal
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 23, "P": 132, "K": 200, "ph": 6.0, "humidity": 82.0, "electrical_conductivity": 0.4, "plant": "grapes"}'

# TEST 7: Maize - potassium deficient
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 80, "P": 60, "K": 5, "ph": 6.2, "humidity": 55.0, "electrical_conductivity": 0.5, "plant": "maize"}'

# TEST 8: Apple - high salinity
Invoke-RestMethod -Method Post `
  -Uri "http://localhost:8001/plant-growth" `
  -ContentType "application/json" `
  -Body '{"N": 21, "P": 134, "K": 199, "ph": 5.8, "humidity": 92.0, "electrical_conductivity": 3.5, "plant": "apple"}'
