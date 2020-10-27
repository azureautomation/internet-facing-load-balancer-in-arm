Internet facing load balancer in ARM
====================================

            

The script will promt to build one of the following examples:


Build example IPv4 public IP address load balancer
Build example IPv6 public IP address load balancer
Build example IPv4 private IP address load balancer


·        
Allow the user to select the number of IP addresses to load balance


·        
Allow for dynamic or Static IP addresses



·        
Allows the option the create VM and attach to new load balancer



·        
Allows VM size section



·        
Allow VM storage account selection


·        
Username and password prompt for VM  


·        
Downloads the RDP file for VM connectivity      



 


The Script has the following limitations:


·        
New Vnet \ Resource group built each run



·        
Last mile commands must be run inside the script created Azure VM



 


The following will be created:



a NAT rule to translate all incoming traffic on port 3387 to port 3389


a NAT rule to translate all incoming traffic on port 3388 to port 3389.


a NSG to allow RDP and HTTP traffic.


a load balancer rule to balance all incoming traffic on port 80 to port 8080 on the addresses in the back end pool.


a probe TCP probe which will test traffic on back end port 8080


** *** *


 

 

 

 

        
    
TechNet gallery is retiring! This script was migrated from TechNet script center to GitHub by Microsoft Azure Automation product group. All the Script Center fields like Rating, RatingCount and DownloadCount have been carried over to Github as-is for the migrated scripts only. Note : The Script Center fields will not be applicable for the new repositories created in Github & hence those fields will not show up for new Github repositories.
