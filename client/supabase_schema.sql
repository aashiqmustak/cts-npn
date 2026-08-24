-- ====================================================================
-- ALTERNEA HEALTHCARE ECOSYSTEM - SUPABASE DATABASE SCHEMA
-- Clean Schema Setup for Live Dynamic Data Creation (Zero Static Datasets)
-- ====================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. DROP EXISTING TABLES & VIEWS (Clean Slate)
DROP VIEW IF EXISTS alternatives CASCADE;
DROP TABLE IF EXISTS pharmacist_dispense_records CASCADE;
DROP TABLE IF EXISTS formulary_alternatives CASCADE;
DROP TABLE IF EXISTS pa_friction_events CASCADE;
DROP TABLE IF EXISTS adherence_flags CASCADE;
DROP TABLE IF EXISTS patient_medicine_logs CASCADE;
DROP TABLE IF EXISTS prescription_items CASCADE;
DROP TABLE IF EXISTS prescriptions CASCADE;
DROP TABLE IF EXISTS drugs CASCADE;
DROP TABLE IF EXISTS plans CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;
DROP TABLE IF EXISTS hospitals CASCADE;
DROP TABLE IF EXISTS otp_codes CASCADE;

-- 3. HOSPITALS TABLE
CREATE TABLE hospitals (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    address TEXT NOT NULL DEFAULT '',
    city TEXT NOT NULL DEFAULT '',
    state TEXT NOT NULL DEFAULT 'NY',
    zip TEXT NOT NULL DEFAULT '',
    phone TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. DOCTORS TABLE
CREATE TABLE doctors (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    specialty TEXT NOT NULL DEFAULT 'General Practice',
    email TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. PATIENTS TABLE
CREATE TABLE patients (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    email TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    age INT NOT NULL DEFAULT 40,
    gender TEXT NOT NULL DEFAULT 'Other',
    current_problem TEXT DEFAULT '',
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    assigned_doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    prescriber_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE SET NULL,
    plan_id TEXT,
    risk_score DOUBLE PRECISION DEFAULT 0.25,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. USER PROFILES TABLE (Mapped to Supabase Auth UID)
CREATE TABLE user_profiles (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    name TEXT NOT NULL DEFAULT 'User',
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'patient',
    title TEXT,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE SET NULL,
    hospital_name TEXT,
    doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
    avatar_url TEXT,
    insurance_company TEXT,
    insurance_plans JSONB DEFAULT '[]'::jsonb,
    insurance_medicines JSONB DEFAULT '[]'::jsonb,
    insurance_hospitals JSONB DEFAULT '[]'::jsonb,
    assigned_patient_ids JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. INSURANCE PLANS TABLE
CREATE TABLE plans (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    cms_plan_id TEXT NOT NULL DEFAULT '',
    total_enrollees INT NOT NULL DEFAULT 0,
    formulary_year INT NOT NULL DEFAULT 2026,
    deductible DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. DRUGS CATALOG TABLE
CREATE TABLE drugs (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    name TEXT NOT NULL,
    ndc TEXT NOT NULL DEFAULT '',
    tier INT NOT NULL DEFAULT 1,
    plan_id TEXT REFERENCES plans(id) ON DELETE SET NULL,
    drug_class TEXT NOT NULL DEFAULT 'General',
    cost_share DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    requires_pa BOOLEAN DEFAULT FALSE,
    step_therapy BOOLEAN DEFAULT FALSE,
    quantity_limit BOOLEAN DEFAULT FALSE,
    est_monthly_cost DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. PRESCRIPTIONS TABLE
CREATE TABLE prescriptions (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
    doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    hospital_id TEXT REFERENCES hospitals(id) ON DELETE SET NULL,
    prescribed_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'Prescribed', -- 'Prescribed', 'Partially Dispensed', 'Dispensed', 'Active', 'Cancelled'
    diagnosis TEXT,
    notes TEXT,
    drug_id TEXT,
    drug_name TEXT,
    drug_class TEXT DEFAULT 'General',
    pdc_score DOUBLE PRECISION DEFAULT 0.85,
    last_fill_date TIMESTAMP WITH TIME ZONE,
    next_due_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 10. PRESCRIPTION ITEMS TABLE
CREATE TABLE prescription_items (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE CASCADE,
    medicine_name TEXT NOT NULL,
    dosage TEXT NOT NULL DEFAULT '',
    frequency TEXT NOT NULL DEFAULT '',
    duration_days INT NOT NULL DEFAULT 30,
    is_dispensed BOOLEAN NOT NULL DEFAULT FALSE,
    dispensed_at TIMESTAMP WITH TIME ZONE,
    instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. PATIENT MEDICINE LOGS TABLE (Interactive Daily Med Tracker)
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

-- 12. ADHERENCE FLAGS TABLE
CREATE TABLE adherence_flags (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE SET NULL,
    patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
    patient_name TEXT NOT NULL,
    drug_name TEXT NOT NULL,
    drug_class TEXT NOT NULL,
    risk_level TEXT NOT NULL DEFAULT 'medium',
    pdc_score DOUBLE PRECISION NOT NULL DEFAULT 0.70,
    reason TEXT NOT NULL DEFAULT '',
    outreach_status TEXT NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 13. PRIOR AUTH FRICTION EVENTS TABLE
CREATE TABLE pa_friction_events (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE SET NULL,
    patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
    patient_name TEXT NOT NULL,
    drug_name TEXT NOT NULL,
    days_delayed INT NOT NULL DEFAULT 0,
    friction_score DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    status TEXT NOT NULL DEFAULT 'blocked',
    barrier_type TEXT NOT NULL DEFAULT 'paRequired',
    suggested_alt_name TEXT,
    est_annual_savings DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 14. FORMULARY ALTERNATIVES TABLE
CREATE TABLE formulary_alternatives (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    target_drug_id TEXT REFERENCES drugs(id) ON DELETE SET NULL,
    alt_drug_id TEXT REFERENCES drugs(id) ON DELETE SET NULL,
    alt_drug_name TEXT NOT NULL,
    alt_tier INT NOT NULL DEFAULT 1,
    est_monthly_savings DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    est_annual_savings DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    copay_diff DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    requires_pa BOOLEAN DEFAULT FALSE,
    clinical_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Backward compatibility view
CREATE OR REPLACE VIEW alternatives AS SELECT * FROM formulary_alternatives;

-- 15. PHARMACIST DISPENSE RECORDS TABLE (Audit Log)
CREATE TABLE pharmacist_dispense_records (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    prescription_id TEXT REFERENCES prescriptions(id) ON DELETE SET NULL,
    prescription_item_id TEXT REFERENCES prescription_items(id) ON DELETE SET NULL,
    patient_id TEXT REFERENCES patients(id) ON DELETE SET NULL,
    patient_name TEXT NOT NULL DEFAULT '',
    doctor_id TEXT REFERENCES doctors(id) ON DELETE SET NULL,
    doctor_name TEXT NOT NULL DEFAULT '',
    pharmacist_id TEXT REFERENCES user_profiles(id) ON DELETE SET NULL,
    pharmacist_name TEXT NOT NULL DEFAULT '',
    medicine_name TEXT NOT NULL,
    dosage TEXT NOT NULL DEFAULT '',
    frequency TEXT NOT NULL DEFAULT '',
    dispensed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 16. OTP CODES TABLE
CREATE TABLE otp_codes (
    id TEXT PRIMARY KEY DEFAULT uuid_generate_v4()::text,
    email TEXT NOT NULL,
    otp_code TEXT NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '10 minutes'),
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ====================================================================
-- 16. DOCTOR LICENCE TABLE (Medical Board Verification Registry)
CREATE TABLE doctor_licence (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    licence_number VARCHAR NOT NULL,
    email VARCHAR NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Sample Initial Seeds for Doctor License Registry
INSERT INTO doctor_licence (licence_number, email) VALUES
    ('LIC-2026-9041', 'dr.sarah@alternea.com'),
    ('MD-44821', 'dr.verma@alternea.com'),
    ('DOC-882190', 'doctor@alternea.com'),
    ('LIC-77491', 'doctor01@gmail.com')
ON CONFLICT DO NOTHING;

-- 17. ENABLE ROW LEVEL SECURITY (RLS) & UNRESTRICTED APP ACCESS POLICIES
-- ====================================================================
ALTER TABLE hospitals ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctor_licence ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE drugs ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prescription_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_medicine_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE adherence_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE pa_friction_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE formulary_alternatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE pharmacist_dispense_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE otp_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow All on hospitals" ON hospitals FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on doctors" ON doctors FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on doctor_licence" ON doctor_licence FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on patients" ON patients FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on user_profiles" ON user_profiles FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on plans" ON plans FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on drugs" ON drugs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on prescriptions" ON prescriptions FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on prescription_items" ON prescription_items FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on patient_medicine_logs" ON patient_medicine_logs FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on adherence_flags" ON adherence_flags FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on pa_friction_events" ON pa_friction_events FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on formulary_alternatives" ON formulary_alternatives FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on pharmacist_dispense_records" ON pharmacist_dispense_records FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow All on otp_codes" ON otp_codes FOR ALL USING (true) WITH CHECK (true);

-- ====================================================================
-- 18. AUTOMATED SUPABASE AUTH TRIGGER (Links Auth Users to User Profiles)
-- ====================================================================
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
    'User'
  );
  
  extracted_role := COALESCE(
    NEW.raw_user_meta_data->>'role',
    'patient'
  );

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
    'Member',
    extracted_avatar
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = EXCLUDED.name,
    avatar_url = EXCLUDED.avatar_url;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
