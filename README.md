# DomainConnectDDNS-BASH
With this BASH script we can solve the error we found with domain-connect-dyndns in Python "Domain doesn't support Domain Connect."  It uses the IONOS API, which is free.

https://developer.hosting.ionos.es/

![image](https://github.com/user-attachments/assets/33447766-fc51-4394-b582-d8fdb3ba2b4b)



![image](https://github.com/user-attachments/assets/e5894f97-41dc-4e13-991f-8aa4704d2ade)




![image](https://github.com/user-attachments/assets/ac6e4ec4-e6c3-4827-a0d4-20fdb2663410)



![image](https://github.com/user-attachments/assets/d70e30e8-f666-4901-ae99-14970b128a17)



API_KEY="public.private"
DOMAINS=("domain1.es" "subdomain1.eu" "subdomain2.com")  # Lista de dominios y subdominios
IP_FILE="current_ip.txt"
telegramBotToken='token_telegram' #OPTIONAL
telegramChatID='chatid' #OPTIONAL
