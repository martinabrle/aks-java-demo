CREATE TABLE IF NOT EXISTS visits (
  "id" INT SERIAL PRIMARY KEY NOT NULL,
  "pet_id" INT NOT NULL,
  "visit_date" DATE,
  "description" VARCHAR(8192),
  FOREIGN KEY ("pet_id") REFERENCES pets("id")
);
