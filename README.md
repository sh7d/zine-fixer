# Zine fixer
## O projekcie
Generyczny sposób na naprawę magazynów internetowych spisanych w czasach królowania IE.  
Celem było stworzenie narzędzia które pozwoli na serwowanie zinowych treści w formie online.
## Użytkowanie
```
bundle install
```
```
zine-fixer - generyczny renowator do zinów

Użycie: zinefixer.rb [opcje]
Profile:
    -l, --list-profiles              Wylistowywuje dostępne profile, wraz z opcjami
    -p profile1,profile2,profile3,   Aktywuje wybrane profile (Domyślne: stable)
        --profiles

Ręczna aktywacja fixów:
        --downcase-filenames         Downcase-uje nazwy plików
        --downcase-attributes        Downcase-uje ścieżki plików w atrybutach plików html
        --downcase-files-strings     Downcase-uje ciągi znaków ścieżek do plików
        --js-top                     Zmiana wywołań funkcji js_top
        --js-fix-flash               Fix flash embedowany przez document.write (niepotrzebne)

Wspólne opcje:
    -d, --dirname PATH               Wymagane: Ścieżka do katalogu z zinem
    -v, --verbose VERBOSITY          Ustawia poziom gadatliwości - domyślnie 0

Pozostałe:
    -h, --help                       Wyświetla tą pomoc
```
`ex: ruby zinefixer.rb -v 3 -d '/home/tomek/Workspace/am/Action Mag 004'`
*Ruby version:* ruby 2.6.3
## Status
Good enough.  
Stabilny profil jest stabilny, aczkolwiek parsowanie htmla ze względu na cuda z kodowaniem (może użyć HTMLFragment?) i chęcią zostawienia działającego jsa, raczej mocno eksperymentalne.  

Nad decyzjami osób piszącymi htmla mozna się długo rozpisywać (ezoterycznie: `document.write('<hehe_object>hehe flash</hehe_object>/>')` jako menu boczne), jednakże strony renderuja się nadzwyczaj dobrze.  

## Known bugs && faq
### Flash nie wyświetla się kiedy strona jest otwatra lokalnie.
Jest to spowodowane polityką bezpieczeństwa przeglądarki.  
Dzisiaj dockerem trzeba dostarczac wszystko. Smutne
### Kodowanie znaków
1. rchardet nie daje sobie rady z detekcją wschodnich kodowań
2. odnośniki do plików przetworzone mogą mieć inne bajty - ich nazwa nie będzie odpowiadała celowi
