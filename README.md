# bird_paradise
This repo contains my first SQL project: A database with tables, relations, procedures, triggers and views to map the retail processes of a small (fictious) retail store.

Hi there and thanks for stopping by!

In this repo you find my first large(r) SQL-project! 

What will you find:
  - Die Umsetzung meines selbst konzipierten, workflow-basierten Warenwirtschaftssystems in SQL!
  - Für einen fiktiven Tierzubehörladen (einzelhandel) habe ich eine Datenbank mit zugehöriger Architektur eingerichtet, die folgendes beinhaltet:
      - eine relationale datenbankstruktur für die abbildung von kunden, produkten, bestellungen, rechnungen, etc. - angelehnt an meine (kurze) berufserfahrung mit warenwirtschaftssystemen des einzelhandels
      - eine business logik für die Anlage von bestellungen und rechnungen
        - automatische lagerbestandsüberprüfung und rechnungsanlage für eingehende bestellungen
        - status- und bearbeitungslogik fpr für abgelehnte (wartende) bestellungen aufgrund von lager-engpässen
        - unterstützende workflows für die abwicklung offener und bausierter bestellungen
      - unterstützende views für betriebswirtschaftliches monitoring anhand von kenngrößen des einzelhandels
  - dabei wurde auf die referentielle integrität der daten und ein sauberes handling von statusübergängen der relevanten datenobjekte geachtet
  - besonders stolz bin ich auf die zentrale prozesskette zur abwicklung der kernworkflows, die mithilfe von prozeduren und datenbanktriggern umgesetzt wurde
  - für einen schnellsten Überblick: Schaut euch die Dokumentation an (
As at the current point in time,
