# bird_paradise
This repo contains my first SQL project: A database with tables, relations, procedures, triggers, and views to model the retail processes of a small (fictitious) retail store.

## Hi there and thanks for stopping by!

In this repo, you'll find my first larger SQL project!  

### What will you find?
- The implementation of my self-designed, workflow-based ERP for retail in SQL!
- I have set up a database and its architecture for a fictitious pet supply store (retail), which includes:
  - A relational database structure for mapping customers, products, orders, invoices, etc., inspired by my (short) professional experience with retail ERP.
  - Business logic for handling orders and invoices:
    - Automatic stock level verification and invoice creation for incoming orders.
    - Status and processing logic for rejected (pending) orders due to stock shortages.
    - Supporting workflows for processing open and completed orders.
  - Supporting views for business monitoring based on key retail metrics.
- The project ensures referential integrity and a clean handling of status transitions for relevant data objects.
- I am particularly proud of the core process chain for managing the key workflows, which is implemented using stored procedures and database triggers.
- **For a quick overview:** BEST check out the documentation (`Projektdokumentation birds paradise.pdf`) which you find at the same dir level as this README.

> As of now, the documentation is only available in German – sorry for that!  

Feel free to contact me anytime if you have questions, ideas for improvement, or feedback. I appreciate any input!  

**Best,  
Patrick**  
