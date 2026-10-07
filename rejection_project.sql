## create database info
show databases;
USE info;
RENAME TABLE `raw data 1` TO raw_data_1;

CREATE TABLE raw_data_backup LIKE raw_data_1;

-- คัดลอกข้อมูล
INSERT INTO raw_data_backup SELECT * FROM raw_data_1;
select * from raw_data_backup;

UPDATE raw_data_backup
SET 
    customer_id = TRIM(customer_id),
    
    -- คลีนค่าอายุ
    age = CAST(age AS UNSIGNED),
    
    -- ข้อความเพศและอาชีพ
    gender = LOWER(TRIM(gender)),
    employment_status = LOWER(TRIM(employment_status)),
    
    -- CAST เฉพาะ revolving_utilization_origination เป็น DECIMAL(5,2)
    revolving_utilization_origination = CAST(revolving_utilization_origination AS DECIMAL(5,2)),
    
    -- คลีนรูปแบบข้อความ deterioration_pattern
    deterioration_pattern = LOWER(TRIM(deterioration_pattern))

WHERE customer_id IS NOT NULL 
  AND customer_id != '';
  select * from raw_data_backup;
  
  SELECT 
    customer_id,
    age,
    gender,
    employment_status,
    monthly_income,
    loan_amount,
    emi,
    -- คำนวณเงินคงเหลือชำระหนี้ต่อเดือน (Residual Income)
    (monthly_income - emi) AS residual_income,
    
    credit_score_origination AS credit_score,
    dti,
    revolving_utilization_origination AS revolving_utilization,
    credit_inquiries_12m,
    deterioration_pattern,
    
    -- 1. ประเมินสถานะการคัดกรอง (Screening Status)
    CASE 
        WHEN dti > 0.50 
          OR revolving_utilization_origination > 0.85 THEN 'Rejected'
        WHEN credit_inquiries_12m >= 4 
         AND LOWER(deterioration_pattern) = 'credit_seeking' THEN 'Rejected'
        WHEN (monthly_income - emi) < 8000 THEN 'Rejected'
        ELSE 'Passed'
    END AS screening_status,
    
    -- 2. ระบุสาเหตุหลักในการปฏิเสธ (Reject Reason)
    CASE 
        WHEN dti > 0.50 THEN 'High DTI Burden (>50%)'
        WHEN revolving_utilization_origination > 0.85 THEN 'High Credit Utilization (>85%)'
        WHEN credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking' THEN 'Credit Seeking Behavior'
        WHEN (monthly_income - emi) < 8000 THEN 'Low Residual Income (<8,000 THB)'
        ELSE 'Eligible'
    END AS reject_reason

FROM raw_data_backup;

SELECT 
    employment_status,
    deterioration_pattern,
    COUNT(*) AS total_applicants,
    
    -- จำนวนคนที่ติด Red Flag (Rejected)
    SUM(CASE 
        WHEN dti > 0.50 
          OR revolving_utilization_origination > 0.85 
          OR (credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking') 
          OR (monthly_income - emi) < 8000 
        THEN 1 ELSE 0 
    END) AS total_rejected,
    
    -- จำนวนคนที่ผ่านเกณฑ์ (Passed)
    SUM(CASE 
        WHEN NOT (
            dti > 0.50 
            OR revolving_utilization_origination > 0.85 
            OR (credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking') 
            OR (monthly_income - emi) < 8000
        ) 
        THEN 1 ELSE 0 
    END) AS total_passed,
    
    -- คำนวณอัตราส่วน % การ Rejected
    ROUND(
        (SUM(CASE 
            WHEN dti > 0.50 
              OR revolving_utilization_origination > 0.85 
              OR (credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking') 
              OR (monthly_income - emi) < 8000 
            THEN 1 ELSE 0 
        END) / COUNT(*)) * 100
    , 2) AS reject_rate_pct
FROM raw_data_backup
GROUP BY employment_status, deterioration_pattern
ORDER BY total_applicants DESC;
  
  -- analysis part
  
SELECT 
    -- ประเมินสถานะการคัดกรอง
    CASE 
        WHEN dti > 0.50 OR revolving_utilization_origination > 0.85 THEN 'Rejected'
        WHEN credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking' THEN 'Rejected'
        WHEN (monthly_income - emi) < 8000 THEN 'Rejected'
        ELSE 'Passed'
    END AS screening_status,
    
    COUNT(*) AS total_applicants,
    
    -- เม็ดเงินขอกู้รวม (THB)
    SUM(loan_amount) AS total_loan_requested,
    
    -- เฉลี่ยเงินขอกู้ต่อราย (THB)
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    
    -- สัดส่วนเม็ดเงินเทียบกับพอร์ตทั้งหมด (%)
    ROUND((SUM(loan_amount) / (SELECT SUM(loan_amount) FROM raw_data_backup)) * 100, 2) AS portfolio_share_pct,
    
    -- ดอกเบี้ยคาดการณ์รวมต่อปี (Financial Revenue Potential)
    ROUND(SUM(loan_amount * (interest_rate / 100)), 2) AS estimated_annual_interest_revenue

FROM raw_data_backup
GROUP BY screening_status;

-- anslysis 2
SELECT 
    employment_status,
    
    -- นับจำนวนตามสาเหตุการ Reject
    COUNT(*) AS total_applicants,
    SUM(CASE WHEN dti > 0.50 THEN 1 ELSE 0 END) AS high_dti_count,
    SUM(CASE WHEN revolving_utilization_origination > 0.85 THEN 1 ELSE 0 END) AS high_utilization_count,
    SUM(CASE WHEN credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking' THEN 1 ELSE 0 END) AS credit_seeking_count,
    SUM(CASE WHEN (monthly_income - emi) < 8000 THEN 1 ELSE 0 END) AS low_residual_income_count,
    
    -- อัตราการติด Red Flag รายอาชีพ (%)
    ROUND(
        (SUM(CASE 
            WHEN dti > 0.50 
              OR revolving_utilization_origination > 0.85 
              OR (credit_inquiries_12m >= 4 AND LOWER(deterioration_pattern) = 'credit_seeking') 
              OR (monthly_income - emi) < 8000 
            THEN 1 ELSE 0 
        END) / COUNT(*)) * 100
    , 2) AS segment_reject_rate_pct

FROM raw_data_backup
GROUP BY employment_status
ORDER BY total_applicants DESC;


