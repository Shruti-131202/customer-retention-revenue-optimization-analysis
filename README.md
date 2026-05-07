# customer-retention-revenue-optimization-analysis
This project identifies a critical revenue risk: ~80% customers drop after their first purchase, while ~67% revenue depends on a small customer segment.

The analysis focuses on improving early retention to unlock high-impact revenue growth.
##  Business Problem

The business is experiencing high customer drop-off after the first purchase, limiting revenue growth. 

Despite a strong base of repeat customers, revenue is highly dependent on a small segment, creating concentration risk.

The goal of this project is to identify retention gaps, analyze customer behavior, and uncover opportunities to improve repeat purchases and overall revenue.

##  Key Insights

• ~79% of customers drop after their first purchase, indicating weak early retention

• Only ~20% of customers are retained in Month 1, highlighting onboarding gaps

• Top customer segments (Champions & Loyal) contribute ~67% of total revenue → high dependency risk

• Revenue is heavily concentrated in a single geography (UK ~80%+)

• Retention stabilizes after Month 3, indicating presence of a loyal core customer base

##  Business Recommendations

• Improve first 30-day onboarding to increase second purchase conversion

• Target At-Risk and New Customers through re-engagement campaigns

• Expand repeat customer base to reduce revenue concentration risk

• Focus on retention strategies, as improving retention is more cost-effective than acquiring new customers

##  Potential Impact

• Improving Month 1 retention from ~20% to ~30% can significantly increase repeat customer base and revenue contribution

• Small improvements in retention can drive disproportionate revenue growth due to high dependency on repeat customers

##  Dashboard Overview

The Power BI dashboard provides a business-focused view across three key areas:

• Executive Summary: Revenue, repeat rate, and concentration risks  
<img width="889" height="499" alt="Executive" src="https://github.com/user-attachments/assets/424a91ef-eac2-4636-b3f1-6c3ce7e61331" />

• Customer Segmentation: RFM-based analysis to identify high-value and at-risk segments  
<img width="901" height="500" alt="RFM_Analysis" src="https://github.com/user-attachments/assets/4cb1fb9b-5ad2-45a3-b7f6-3a50cae73ae8" />
• Retention Analysis: Cohort-based tracking of customer behavior over time  
<img width="892" height="480" alt="Cohort_Analysis" src="https://github.com/user-attachments/assets/dcd65195-086e-446d-9995-f480e4d4d651" />

## ⚙️ Technical Approach

• Data Cleaning & Transformation using SQL (MySQL)

• Created business-ready dataset by removing invalid transactions and handling missing values

•  Implemented advanced SQL using window functions (NTILE, FIRST_VALUE) for RFM segmentation and cohort analysis

• Built cohort analysis to track customer retention trends

• Developed an interactive dashboard in Power BI for business insights

## 🛠️ Tools Used

• SQL (MySQL)  
• Power BI  
• Excel  

##  Conclusion

- This analysis highlights that the business is heavily dependent on a small group of high-value customers, while a majority of customers drop off after their first purchase.

- The key growth opportunity lies in improving early-stage retention, particularly within the first 30 days, where the highest customer drop-off occurs.

- By focusing on onboarding, increasing second purchase conversion, and targeting at-risk customers, the business can significantly improve repeat purchases and overall revenue.

This project demonstrates how data-driven retention strategies can drive sustainable and cost-effective growth.
