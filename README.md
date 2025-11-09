# Login Pagina Frontend

Een moderne, responsive login pagina met gebruikersnaam en wachtwoord velden.

## Functies

- Gebruikersnaam en wachtwoord invoer
- Real-time formulier validatie
- Foutmeldingen
- "Onthoud mij" functionaliteit
- Loading state tijdens inloggen
- Responsive design (werkt op desktop en mobiel)
- Moderne, gebruiksvriendelijke interface

## Gebruik

1. Open `index.html` in een webbrowser
2. Voer je gebruikersnaam en wachtwoord in
3. Klik op "Inloggen"

## Demo Inloggegevens

Voor test doeleinden:
- **Gebruikersnaam**: `demo`
- **Wachtwoord**: `demo123`

## Validatie Regels

- **Gebruikersnaam**: minimaal 3 karakters
- **Wachtwoord**: minimaal 6 karakters
- Beide velden zijn verplicht

## Bestanden

- `index.html` - Hoofdpagina met login formulier
- `styles.css` - Styling en layout
- `script.js` - Formulier validatie en login logica

## Technologieën

- HTML5
- CSS3 (met CSS variabelen en animaties)
- Vanilla JavaScript (ES6+)

## Features

### Beveiliging
- Password veld is gemaskeerd
- Validatie aan client-side
- Token opslag (localStorage voor "onthoud mij", sessionStorage anders)
- XSS preventie door input sanitization

### Gebruikerservaring
- Real-time validatie feedback
- Loading indicator tijdens inloggen
- Duidelijke foutmeldingen
- Toegankelijk met keyboard navigatie
- Responsive design voor alle schermformaten

## Aanpassen voor Productie

Om deze login pagina te gebruiken in productie:

1. **Vervang de mock API call** in `script.js`:
   ```javascript
   async function loginUser(username, password, rememberMe) {
       const response = await fetch('/api/login', {
           method: 'POST',
           headers: {
               'Content-Type': 'application/json',
           },
           body: JSON.stringify({ username, password, rememberMe })
       });

       if (!response.ok) {
           throw new Error('Login mislukt');
       }

       return await response.json();
   }
   ```

2. **Verwijder demo credentials** uit de console.log statements

3. **Implementeer echte redirect** naar dashboard pagina na succesvolle login

4. **Voeg HTTPS** toe voor veilige communicatie

5. **Implementeer CSRF bescherming**

6. **Voeg rate limiting** toe om brute force aanvallen te voorkomen

## Browser Ondersteuning

- Chrome (laatste 2 versies)
- Firefox (laatste 2 versies)
- Safari (laatste 2 versies)
- Edge (laatste 2 versies)

## Licentie

MIT
