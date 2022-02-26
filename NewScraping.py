#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Feb 15 19:55:22 2022

@author: ubuntu
"""

'''
bs4 mi prende solo le cose testuali, non mi permette ne di cliccare ne di fare altro
con webdrive posso cliccare,......
'''


import tkinter as tk
import tkinter.filedialog as file
import pandas as pd
from selenium import webdriver
from selenium.webdriver.common.keys import Keys
import time
import bs4
#from pynput.keyboard import Key, Controller #percliccare
import pyautogui  #per simulare tastieta
import threading
import os
import psycopg2


#variabli globali
percorsoFileiniziale=''
percorsoFileFinale=''
LINKMAPS='https://www.google.it/maps/@41.111399,16.8768417,15z'
area=0
listaDizionario=[]
dizionario = {}
ultimoIdturista=0

#variabili per la conessione al db
conn=0
cursore=0

#il metodo vai cerca di scorrere tutta la pagina
def vai(num):
    global area
    time.sleep(2)
    pyautogui.hotkey('tab')  
    
    #per evitare di surriscaldare il pc dipenda la dimensione faccio il pulsante page down
    
    
    if num>1000:
        num=int(num/100)
        x=500
    else:
        x=num
    
    for i in range(0,num):
        
        #per fare vedere il lampeggiare
        if i%2==0:
            area.config(stat="normal") 
            area.insert(tk.END,'\n_')
       
        area.config(stat="disable") 
    
        pyautogui.press('pgdn',x,interval=0.000001)  #clicca 20 volte per scendere la pagina
        #poiche si potrebbe bloccare  una volta tanto vieno cliccato tab
        if i%5==0:
            pyautogui.hotkey('tab')  
        print(i)
        #per fare vedere il lampeggiare
        if i%2==0:
            area.config(stat="normal") 
            area.delete('end-1l','end')
            area.config(stat="disable") 
            
    pyautogui.PAUSE  #mi serve per evitare che continui a cliccare anche dopo il ciclo
        
        
        
    
#clicca i tastiper superare i coocki iniziali
def evitoCookiIniziali():
    pyautogui.hotkey('tab')
    pyautogui.hotkey('tab')
    pyautogui.hotkey('tab')
    pyautogui.hotkey('tab')
    pyautogui.hotkey('enter')
    time.sleep(2)


#se il numero delle reccensione e diverso dan numero totale preso di utenti riprovo
def riprovo(driver,num,div):
    contatoreRicerca=0
    while num!=len(div) and contatoreRicerca<2:
        area.config(stat="normal") 
        area.insert(tk.END,'Non sono riuscito a prendere tutti i turisti riprovo(questa procedura puo avvenire ad un massimo di 10 volte)\n')
        area.config(stat="disable") 
        print('sono dentro il riclo di ripescaggio')
        time.sleep(2)
        
        vai(num)
        
        time.sleep(2)
        #una volta caricata tutta la pagina completa, mi prendo il tag che mi serve
        soup=bs4.BeautifulSoup(driver.page_source,'html.parser')
        div = soup.findAll('div',attrs={'class':'ODSEW-ShBeI NIyLF-haAclf gm2-body-2'})
        contatoreRicerca +=1 
        
    return div,num
  


#eseguo la ricerca con l'aggiunta di basilicata se questa non è andata a buoin fine provo senza altrimenti stampo un errore e vado avanti      
def cerco(driver,nome):
    global LINKMAPS
    driver.get(LINKMAPS)
    pp=driver.find_element_by_name("q")
    print(pp.tag_name,'##############')
    pp.send_keys(nome)
    pp.send_keys(Keys.RETURN) #da il compo di invio
    time.sleep(5)
    
    soup=bs4.BeautifulSoup(driver.page_source,'html.parser')   #cosi prendo la pagina corrente
    nrec=-1
    try:
        nrec = soup.find('button',attrs={'class':'Yr7JMd-pane-hSRGPd'}).text  #prendo il tag dove ce scritto ilnumero delle recenioni
        print(nrec+'hola22')
    except AttributeError:
       
        print('hola33')
        return -1
    return nrec



def scriviFile(nomeH):
    global area
    global conn
    global cursore
    global ultimoIdturista
    area.config(stat='normal')
    area.insert(tk.END,'sto scrivendo sul file \n')
    area.config(stat="disable") 
    nome = []
    tempo = []
    stelle = []
    print('sono in scrivi file')
    with open(percorsoFileFinale+'/provaNome.txt','r',encoding="utf-8") as f:
                for record in f:
                    nome.append(record)
    print('sono in scrivi file1')          
    with open(percorsoFileFinale+'/provaTempo.txt','r',encoding="utf-8") as f:
                 for record in f:
                     tempo.append(record)
    print('sono in scrivi file2')            
    with open(percorsoFileFinale+'/provaVal.txt','r',encoding="utf-8") as f:
                 for record in f:
                     stelle.append(record)
    
    print('sono in scrivi file3')
    os.remove(percorsoFileFinale+'/provaNome.txt')
    os.remove(percorsoFileFinale+'/provaTempo.txt')
    os.remove(percorsoFileFinale+'/provaVal.txt')
    
    print(nome)
    print(tempo)
    print(stelle)
    print('sono in scrivi file4')
    #scrivo su un file per sicurezza
    with open(percorsoFileFinale+'/fileFinale.txt','a',encoding="utf-8") as f:
                for i in range(0,len(nome)):
                    print(i,'ciclo\n',nome[i].replace('\n', ';')+tempo[i].replace('\n', ';')+stelle[i].replace('\n', ';')+';\n')
                    s=nome[i].replace('\n', ';')+tempo[i].replace('\n', ';')+stelle[i].replace('\n', ';')+nomeH+';\n'
                    f.write(s)
   
    
    #pulizia tempo
    for i in range(0,len(tempo)):
        if 'gior' in tempo[i] or 'mes' in tempo[i] or 'un' in tempo[i] or 'settimane' in tempo[i] or 'u' in tempo[i]  :
            tempo[i]=1
        elif 'anni' in tempo[i]:
            tempo[i]=tempo[i][1]   #############################################################DA aggiustare se sono piu di 10 anni non deve prendere solo il rpimo carattere
    
    #pulizia nomi con gli apici
    for i in range(0,len(nome)):
        nome[i]=nome[i].replace("'"," ")
    
    #ora vedo se la struttura gia esiste nel db
    for i in range(0,len(nome)):
        
        if  nomeH  in dizionario.keys() and tempo[i]!=' ':  #controllo sela struttura esiste gia nel db
            print('questa struttura e gia presente lutente e', nome[i])
            
            #prendo l'idi della struttura per verificare se il turista ha gia inserito recensioni uguali la dentro
            idStruttura=dizionario[nomeH]
            print('ok1')
            #controllo se esiste gia questo nickname
            print('tempo e ',tempo[i])
            query = f"select turista.nickname,recensione.voto,recensione.tempo,punto_interesse.nome \
                            from turista inner join recensione on recensione.id_turista=turista.id inner join punto_interesse on recensione.id_punto_interesse=punto_interesse.id \
                            where turista.nickname='{nome[i]}' and recensione.voto={stelle[i]} and recensione.tempo={tempo[i]} and punto_interesse.nome='{nomeH}'; " 
            print('ok2')
            cursore.execute(query)
            print('ok3')
            risultato= cursore.fetchall()
            if risultato:
                print('luntente e gia stato inserito')
            else:
                #print('inserisco nuovo utente',nome[i],nomeH)
                print(f"insert into turista (id,nickname) values({ultimoIdturista},'{nome[i]}');")
                ultimoIdturista+=1
                query =f"insert into turista (id,nickname) values({ultimoIdturista},'{nome[i]}');"
                
                cursore.execute(query)
                print(f"insert into recensione (id,id_turista,id_punto_interesse,voto,tempo) values({ultimoIdturista},{ultimoIdturista},{idStruttura},{stelle[i]},{tempo[i]});")
                query=f"insert into recensione (id,id_turista,id_punto_interesse,voto,tempo) values({ultimoIdturista},{ultimoIdturista},{idStruttura},{stelle[i]},{tempo[i]});"
                cursore.execute(query)
            conn.commit()
            
        else:
            print('questa non era presente l aggiungo subito', nomeH)
            



#inizia la ricerca degli utenyi
def inizioRicerca(driver, nome):
    global LINKMAPS
    global area
    driver.get(LINKMAPS)#scrivo e clicco nella barra di ricerca
    
    evitoCookiIniziali()
    
    
    #eseguo la ricerca con l'aggiunta di basilicata se questa non è andata a buoin fine provo senza altrimenti stampo un errore e vado avanti
    nrec=cerco(driver,nome+' Basilicata')
    if nrec==-1:
        nrec=cerco(driver,nome)
        
    if nrec==-1:
        area.config(stat='normal')
        area.insert(tk.END,'Non Trovata la struttura'+nome+'\noppure si e verificato un errore riavvia il sistema prova ad attendere \n')
        area.config(stat="disable") 
        with open(percorsoFileFinale+'/errore.txt','a') as f:
            f.write(nome+' non è stato trovato\n')
        return  
    
    #estrapolo il numero delle recensioni
    try:
        print(nrec.split(' '))
        nrec=nrec.split(' ')
        num=int(nrec[0].replace('.',''))
        print(num)
    except:
        area.config(stat='normal')
        area.insert(tk.END,'Non Trovata la struttura'+nome+'\noppure si e verificato un errore riavvia il sistema prova ad attendere \n')
        area.config(stat="disable") 
        with open(percorsoFileFinale+'/errore.txt','a') as f:
            f.write(nome+' non è stato trovato\n')
        return 
    
    #scrivo nell'area di testo il nome della struttura ed il numero di recensioni individuate
    area.config(stat="normal") 
    area.insert(tk.END,'per questa struttura '+nome+' ci sono '+str(num)+'recensioni'+'\n')
    area.config(stat="disable") 
    
    #ulteriore controllo di struttura non trovata oppure quella struttura non ha nemmeno una recensione
    if(num<=0):
        area.config(stat="normal") 
        area.insert(tk.END,'la struttura '+nome+' non e stata trovata'+'\n')
        area.config(stat="disable") 
        #aggiungo il nome della struttura non trovata nel file error
        with open(percorsoFileFinale+'/errore.txt','a') as f:
            f.write(nome+' non è stato trovato\n')
        
        return   
    
    
    driver.find_element_by_class_name('Yr7JMd-pane-hSRGPd').click() #faccio click sul bottone
    time.sleep(2)
    vai(num)
    time.sleep(2)
    #una volta caricata tutta la pagina completa, mi prendo il tag che mi serve
    soup=bs4.BeautifulSoup(driver.page_source,'html.parser')
    div = soup.findAll('div',attrs={'class':'ODSEW-ShBeI NIyLF-haAclf gm2-body-2'})
    
    #se il numero delle reccensione e diverso dan numero totale preso di utenti rieseguo la procedura almeno 10 volte
    div,num=riprovo(driver,num,div)
            
    
    print('utenti totale trovati ', len(div))
    
    area.config(stat="normal") 
    area.insert(tk.END,'utenti trovati '+ str(len(div))+' per la struttura '+nome+'\n\n')
    area.config(stat="disable") 
    
    #se non sono riuscito a prendere tutto lo scrivo sul file e sul TEXT
    if num!=len(div):
        area.config(stat="normal") 
        area.insert(tk.END,'guarda non sono riuscito a prenderli tutte le recensioni \n')
        area.config(stat="disable") 
        #aggiungo il nome della struttura non trovata nel file error poiche non sono riusciyo a prenderli tutti, comunque sia contino lo scraping con quello che ho
        with open(percorsoFileFinale+'/errore.txt','a') as f:
            f.write(nome+' non è stato trovato\n')
            
        print('guarda non sono riuscito a prenderli tutti') #################################################################################################
    
    
    #ora scrivo su i file dove seleziono il nome, il voto, il tempo
    #essi sono vettori di un singolo elemento
    count=0
    nonFatti=0
    for j in div:
        
        try:
             nomeT = j.findAll('div',attrs={'class':'ODSEW-ShBeI-title'})
             print(nomeT[0].text)
             with open(percorsoFileFinale+'/provaNome.txt','a',encoding="utf-8") as f:
                         f.write(nomeT[0].text+'\n')
             count+=1
             votazione = j.findAll('span',attrs={'class':'ODSEW-ShBeI-H1e3jb'})
             
             print(votazione[0].get('aria-label')[1])
             with open(percorsoFileFinale+'/provaVal.txt','a',encoding="utf-8") as f:
                             f.write(votazione[0].get('aria-label')[1]+'\n')
           
                 
             tempo = j.findAll('span',attrs={'class':'ODSEW-ShBeI-RgZmSc-date'})
             print(tempo[0].text)
             with open(percorsoFileFinale+'/provaTempo.txt','a',encoding="utf-8") as f:
                         f.write(tempo[0].text+'\n')
        except :
            print('errore michele')
    #se non ci sono stati errori scrivo su i file
    if(count>0):
            scriviFile(nome)
            print('ho finito di scrivewre')
   
    



#creo la conessione con il db mi salvo nel dizionario i punto_interesse.nome e il suo id, e prendo pure l'id dell'ultimo utente
def connessionedb():
    
    global dizionario
    global listaDizionario
    global conn
    global cursore
    global ultimoIdturista
    
    conn=psycopg2.connect(
    host='#######',
    database="#####",
    user="########",
    password="######"
    )

    cursore =conn.cursor()
    
    cursore.execute("select id,nome from punto_interesse ;")
    #conn.commit()    # bisogna inviar tramite il commit
    
    listaDizionario=cursore.fetchall()
    #print(lista)
    
    for i in listaDizionario:
        dizionario[i[1]]=i[0]
        
    print(dizionario)
    
    cursore.execute("select * from turista;")
    listaNomiTurista=cursore.fetchall()    
    print(listaNomiTurista)
    ultimoIdturista=listaNomiTurista[len(listaNomiTurista)-1][0]
    print(ultimoIdturista)
    
    


#secondo step di avvia scraping dove prendo i nomi delle strutture e avvia la funzione inizio ricerca
def avvioSraping2():
    global percorsoFileiniziale
    global percorsoFileFinale 
    global conn
    global cursore
    
    dataset = pd.read_csv(percorsoFileiniziale) #apro il file
                
    lista =list(dataset.name )  #salvo la colonna nome nella lista
    #lista =list(dataset.Denominazione )   #per hotel########################### inserire correttamente il nome della colonna 
    lista2=[]
    #print(lista)
    #faccio una pulizia di lista e salvo tutto in lista 2
    for i in lista:
        s=f'{i}'
        if s!='nan':
            lista2.append(i)
    
    
    #preparo i driver web
    PATHDRIVETR='/home/ubuntu/Scrivania/Programmazione/Programmazione/chromedriver'
    connessionedb()
    
    #ciclo per ogni nomme e vado nel metodoinizo ricerca
    for i in range(0,3):        #################################mettere lu nghezza
        driver=webdriver.Chrome(PATHDRIVETR)
        inizioRicerca(driver,lista2[i])
        #print('sono ritornato')
        driver.close()
        time.sleep(2)
    
    print('terminato')
    conn.commit() 
    cursore.close()        
    conn.close()


def openfile():
    global percorsoFileiniziale
    percorsoFileiniziale=file.askopenfilename()
    print(percorsoFileiniziale)
    if percorsoFileiniziale!='':
        etichetta1conferma=tk.Label(windows,text='✓')
        etichetta1conferma.grid(row=2,column=1)

def openPercorsoFinale():
    global percorsoFileFinale
    percorsoFileFinale=file.askdirectory()
    print(percorsoFileFinale)
    if percorsoFileFinale!='':
        etichetta2conferma=tk.Label(windows,text='✓')
        etichetta2conferma.grid(row=3,column=1)


#primo step di avvio dello scraping
def avviaScraping1():
    global percorsoFileiniziale
    global percorsoFileFinale
    global area
    area=tk.Text(height=30,width=80)
    area.grid(row=5,column=0)
    
    #per non editare
    if(percorsoFileiniziale=="" or percorsoFileFinale==""):
        area.insert(tk.END,'errore nei percorsi specificati\n')
        area.config(stat="disable")   #con normal si puo scrivere
        
    else:
        area.delete("1.0",tk.END)
        area.insert(tk.END,'Avvio Sraping \nATTENZIONE NON USARE IL PC POICHE QUESTO SISTEMA USA LA SIMULAZIONE DEI TASTI, CI VUOLE DEL TEMPO SI PREGA DI AVERE PAZIENZA\n\n')
        area.config(stat="disable")   #con normal si puo scrivere
        
        #crea la cartella relativa dove poter mettere i file
        nomecartella=percorsoFileiniziale.split('/')
        nomecartella=nomecartella[len(nomecartella)-1]
        print(nomecartella[:-4]+' scraping')
        percorsoFileFinale+='/'+nomecartella[:-4]+' scraping'
        if not os.path.exists(percorsoFileFinale):
            os.mkdir(percorsoFileFinale)
        
        #thread
        t1=threading.Thread(target=avvioSraping2)
        t1.start()                      
        #avvioSraping()
    
        
    
    

#creazione grafica 
windows=tk.Tk()
windows.geometry("700x700")
windows.title("progetto Basilicata")
windows.resizable(False,False)   #per impedire di aumentare o diminuire la grandezza della finestra

etichetta=tk.Label(windows,text='Selezione percorsi:   ')
etichetta.grid(row=1,column=0,sticky="N")

buttuonScegliFile=tk.Button(text="ApriFile",command=openfile)
buttuonScegliFile.grid(row=2,column=0,sticky="N")

buttuonScegliPercorsoFinale=tk.Button(text="Apri percorso dove salvare il file",command=openPercorsoFinale)
buttuonScegliPercorsoFinale.grid(row=3,column=0,sticky="N")

buttonAvviaScraping=tk.Button(text='Avvia scraping',command=avviaScraping1,height=3,width=20)
buttonAvviaScraping.grid(row=4,column=0 )




windows.mainloop()  
