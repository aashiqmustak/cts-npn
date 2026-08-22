-- ====================================================================
-- ALTERNEA - SUPABASE DATABASE SCHEMA (CLEAN START FROM SCRATCH)
-- Description: Complete SQL script for Alternea Intelligent Healthcare Ecosystem
-- Instructions: Copy and paste this entire script into your Supabase SQL Editor and run it.
-- ====================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. DROP EXISTING TABLES IF NEEDED
DROP TABLE IF EXISTS patient_medicine_logs CASCADE;
DROP TABLE IF EXISTS prescription_items CASCADE;
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS hospitals CASCADE;
DROP TABLE IF EXISTS pa_friction_events CASCADE;
DROP TABLE IF EXISTS adherence_flags CASCADE;
DROP TABLE IF EXISTS drugs CASCADE;
DROP TABLE IF EXISTS plans CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS otp_codes CASCADE;

-- 3. HOSPITALS TABLE (Hospital name, address, city, state, zip, phone)
CREATE TABLE hospitals (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'NY',
    zip TEXT NOT NULL,
    phone TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. DOCTORS TABLE (Mapped to hospital_id)
CREATE TABLE doctors (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    specialty TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. PATIENTS TABLE (Mapped to assigned doctor_id and hospital_id)
CREATE TABLE patients (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT NOT NULL,
    age INT NOT NULL,
    gender TEXT NOT NULL,
    current_problem TEXT NOT NULL,
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    assigned_doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE SET NULL,
    risk_score DOUBLE PRECISION DEFAULT 0.25,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. PRESCRIPTIONS TABLE (Created by Doctor for Patient at Hospital)
CREATE TABLE prescriptions (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    patient_id TEXT REFERENCES patients(id) ON DELETE CASCADE,
    doctor_id TEXT REFERENCES doctors(id) ON DELETE CASCADE,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE CASCADE,
    prescribed_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'Prescribed', -- 'Prescribed', 'Partially Dispensed', 'Dispensed', 'Cancelled'
    diagnosis TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. PRESCRIPTION ITEMS TABLE (Medicines prescribed to patient)
CREATE TABLE prescription_items (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    duration_days INT NOT NULL DEFAULT 30,
    is_dispensed BOOLEAN NOT NULL DEFAULT FALSE,
    dispensed_at TIMESTAMP WITH TIME ZONE,
    instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. PATIENT MEDICINE LOGS TABLE (Interactive daily log for Patients)
CREATE TABLE patient_medicine_logs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    patient_id TEXT REFERENCES patients(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    scheduled_time TIME NOT NULL DEFAULT '08:00:00',
    is_taken BOOLEAN NOT NULL DEFAULT FALSE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. USER PROFILES TABLE (Mapped to Supabase Auth UID)
CREATE TABLE user_profiles (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL CHECK (role IN ('admin', 'insurance_agent', 'doctor', 'pharmacist', 'patient')),
    title TEXT,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE SET NULL,
    hospital_name TEXT,
    doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. PLANS TABLE (Insurance Plans & Analytics)
CREATE TABLE plans (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    cms_plan_id TEXT NOT NULL,
    total_enrollees INT NOT NULL,
    formulary_year INT NOT NULL,
    deductible DOUBLE PRECISION NOT NULL
);

-- 11. DRUGS TABLE (Formulary Catalog)
CREATE TABLE drugs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    ndc TEXT NOT NULL,
    tier INT NOT NULL,
    plan_id TEXT REFERENCES plans(id) ON DELETE CASCADE,
    drug_class TEXT NOT NULL,
    cost_share DOUBLE PRECISION NOT NULL,
    requires_pa BOOLEAN DEFAULT FALSE,
    step_therapy BOOLEAN DEFAULT FALSE,
    quantity_limit BOOLEAN DEFAULT FALSE,
    est_monthly_cost DOUBLE PRECISION NOT NULL
);

-- 12. ADHERENCE FLAGS TABLE (Risk Graphs & Metrics)
CREATE TABLE adherence_flags (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE CASCADE,
    patient_id TEXT REFERENCES patients(id) ON DELETE CASCADE,
    patient_name TEXT NOT NULL,
    drug_name TEXT NOT NULL,
    drug_class TEXT NOT NULL,
    risk_level TEXT NOT NULL CHECK (risk_level IN ('high', 'medium', 'low')),
    pdc_score DOUBLE PRECISION NOT NULL,
    reason TEXT NOT NULL,
    outreach_status TEXT NOT NULL DEFAULT 'pending',
    notes TEXT
);

-- 13. PA FRICTION EVENTS TABLE (Prior Auth Friction Alerts)
CREATE TABLE pa_friction_events (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE CASCADE,
    patient_id TEXT REFERENCES patients(id) ON DELETE CASCADE,
    patient_name TEXT NOT NULL,
    drug_name TEXT NOT NULL,
    days_delayed INT NOT NULL,
    friction_score DOUBLE PRECISION NOT NULL,
    status TEXT NOT NULL DEFAULT 'blocked',
    barrier_type TEXT NOT NULL,
    suggested_alt_name TEXT,
    est_annual_savings DOUBLE PRECISION NOT NULL
);

-- 14. FORMULARY ALTERNATIVES TABLE (Cheaper Drug Alternatives)
CREATE TABLE formulary_alternatives (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    target_drug_id TEXT REFERENCES drugs(id) ON DELETE CASCADE,
    alt_drug_id TEXT REFERENCES drugs(id) ON DELETE CASCADE,
    alt_drug_name TEXT NOT NULL,
    alt_tier INT NOT NULL,
    est_annual_savings DOUBLE PRECISION NOT NULL,
    requires_pa BOOLEAN DEFAULT FALSE,
    clinical_notes TEXT
);

-- 15. PHARMACIST DISPENSE RECORDS TABLE (Audit log of what pharmacist gave to what patient and who prescribed it)
CREATE TABLE pharmacist_dispense_records (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE SET NULL,
    prescription_item_id TEXT REFERENCES prescription_items(id) ON DELETE SET NULL,
    patient_id TEXT REFERENCES patients(id) ON DELETE CASCADE,
    patient_name TEXT NOT NULL,
    doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    doctor_name TEXT NOT NULL,
    pharmacist_id TEXT REFERENCES user_profiles(id) ON DELETE SET NULL,
    pharmacist_name TEXT NOT NULL,
    medicine_name TEXT NOT NULL,
    dosage TEXT NOT NULL,
    frequency TEXT NOT NULL,
    dispensed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

-- 16. OTP CODES TABLE (Stores verification codes sent via email/SMTP)
CREATE TABLE otp_codes (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '10 minutes'),
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_medicine_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE adherence_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE pa_friction_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE formulary_alternatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacist_dispense_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;

-- Allow public read/write access for application integration
CREATE POLICY "Public Hospitals Access" ON hospitals FOR ALL USING (true);
CREATE POLICY "Public Doctors Access" ON doctors FOR ALL USING (true);
CREATE POLICY "Public Patients Access" ON patients FOR ALL USING (true);
CREATE POLICY "Public Prescriptions Access" ON prescriptions FOR ALL USING (true);
CREATE POLICY "Public Prescription Items Access" ON prescription_items FOR ALL USING (true);
CREATE POLICY "Public Patient Logs Access" ON patient_medicine_logs FOR ALL USING (true);
CREATE POLICY "Public User Profiles Access" ON user_profiles FOR ALL USING (true);
CREATE POLICY "Public Plans Access" ON plans FOR ALL USING (true);
CREATE POLICY "Public Drugs Access" ON drugs FOR ALL USING (true);
CREATE POLICY "Public Adherence Flags Access" ON adherence_flags FOR ALL USING (true);
CREATE POLICY "Public PA Friction Access" ON pa_friction_events FOR ALL USING (true);
CREATE POLICY "Public Formulary Alternatives Access" ON formulary_alternatives FOR ALL USING (true);
CREATE POLICY "Public Pharmacist Dispense Records Access" ON pharmacist_dispense_records FOR ALL USING (true);
CREATE POLICY "Public OTP Codes Access" ON otp_codes FOR ALL USING (true) WITH CHECK (true);

-- 18. AUTOMATED SUPABASE AUTH TRIGGER FOR USER PROFILES
-- Description: Robust trigger handling Google OAuth and email signups
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_name TEXT;
  extracted_role TEXT;
  extracted_avatar TEXT;
BEGIN
  extracted_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1),
    'Authorized User'
  );
  
  extracted_role := COALESCE(
    NEW.raw_user_meta_data->>'role',
    'doctor'
  );
  
  IF extracted_role NOT IN ('admin', 'insurance_agent', 'doctor', 'pharmacist', 'patient') THEN
    extracted_role := 'doctor';
  END IF;

  extracted_avatar := COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture',
    ''
  );

  INSERT INTO public.user_profiles (id, email, name, role, title, avatar_url)
  VALUES (
    NEW.id::text,
    COALESCE(NEW.email, ''),
    extracted_name,
    extracted_role,
    'Authorized User',
    extracted_avatar
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Prevent database trigger error from blocking OAuth user creation
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

