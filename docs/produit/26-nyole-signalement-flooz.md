# 26 — Signalement à nyole / Cartflox : Flooz Togo absent de la page

## Pourquoi ce fichier

Deux problèmes bloquent l'évaluation de nyole (cf.
`25-integration-nyole.md`). Le premier est un écart entre leur API et leur page
de paiement ; le second une limite d'intégration. Les deux leur sont adressés
ici, avec les éléments vérifiables.

## Canaux de contact (il n'y en a pas beaucoup)

- `support@cartflox.com` — Cartflox est la plateforme qui opère nyole (mention
  « Propulsé par Cartflox » en pied de la page de paiement). C'est l'adresse la
  plus directe, et probablement celle de l'équipe qui corrigera la page.
- Formulaire : https://nyole.com/contact (sujet « Une intégration technique »).
  Annonce une réponse sous 24 h ouvrées. Aucun e-mail ni téléphone n'y figure.

Envoyer **aux deux** : le formulaire laisse une trace côté nyole, l'e-mail
touche l'équipe technique.

## Éléments de preuve à citer

- Session concernée : `cmupz5t01005n6l92xc5v6d17` — `livemode: true`, 500 XOF.
- `GET /v1/checkout/sessions/{id}/methods?country=tg` renvoie **trois** moyens :
  `t-money-togo`, `flooz-togo`, `card-xof-stripe` (tous via PayDunya sauf la
  carte via Stripe).
- La page `https://app.nyole.com/checkout/cmupz5t01005n6l92xc5v6d17` n'en
  affiche que **deux** : T-Money Togo et Visa/MasterCard. **Flooz Togo est
  absent.**
- Reproduit aussi en mode test : même liste à trois côté API, même absence
  côté page.

---

## Message — version française

> Objet : Flooz Togo annoncé par l'API mais absent de la page de paiement
>
> Bonjour,
>
> Nous intégrons nyole pour Ablony, une place de marché au Togo et au Bénin, et
> nous rencontrons un écart entre votre API et votre page de paiement.
>
> Pour une session en production (`cmupz5t01005n6l92xc5v6d17`, `livemode: true`,
> 500 XOF), l'appel
> `GET /v1/checkout/sessions/cmupz5t01005n6l92xc5v6d17/methods?country=tg`
> renvoie trois moyens de paiement :
>
> - `t-money-togo` (PayDunya)
> - `flooz-togo` (PayDunya)
> - `card-xof-stripe` (Stripe)
>
> Mais la page de paiement correspondante n'en propose que deux : T-Money Togo
> et Visa/MasterCard. **Flooz Togo n'y apparaît pas.** Nous observons la même
> chose en mode test.
>
> C'est bloquant pour nous : Moov/Flooz représente une part importante des
> paiements mobiles au Togo, et comme la page hébergée est le seul chemin
> d'encaissement, ces clients ne peuvent pas payer du tout.
>
> Deux questions :
>
> 1. S'agit-il d'un incident côté page, ou Flooz Togo est-il réellement
>    indisponible malgré ce que renvoie l'API ? Dans ce dernier cas, l'endpoint
>    `/methods` annonce un moyen qui n'est pas servi.
> 2. Existe-t-il un moyen de **présélectionner** l'opérateur à la création de la
>    session ? Nous demandons déjà son choix au client dans notre application,
>    et nous aimerions éviter qu'il doive le refaire. Nous n'avons trouvé aucun
>    champ en ce sens dans `POST /v1/checkout/sessions` ni dans l'OpenAPI, et
>    les champs `payment_method` / `operator` passés à tout hasard sont ignorés.
>
> Merci d'avance,
> Épiphane-Gédéon — Ablony

---

## Message — version anglaise

> Subject: Flooz Togo returned by the API but missing from the checkout page
>
> Hello,
>
> We are integrating nyole for Ablony, a marketplace in Togo and Benin, and we
> are seeing a mismatch between your API and your checkout page.
>
> For a production session (`cmupz5t01005n6l92xc5v6d17`, `livemode: true`,
> 500 XOF), calling
> `GET /v1/checkout/sessions/cmupz5t01005n6l92xc5v6d17/methods?country=tg`
> returns three payment methods:
>
> - `t-money-togo` (PayDunya)
> - `flooz-togo` (PayDunya)
> - `card-xof-stripe` (Stripe)
>
> However the matching checkout page only offers two: T-Money Togo and
> Visa/MasterCard. **Flooz Togo is not shown.** We see the same in test mode.
>
> This blocks us: Moov/Flooz is a significant share of mobile payments in Togo,
> and since the hosted page is the only way to collect, those customers cannot
> pay at all.
>
> Two questions:
>
> 1. Is this a page-side issue, or is Flooz Togo genuinely unavailable despite
>    what the API returns? In the latter case, `/methods` advertises a method
>    that is not actually served.
> 2. Is there any way to **preselect** the operator when creating the session?
>    We already ask the customer to choose in our app and would rather not make
>    them choose twice. We found no such field in `POST /v1/checkout/sessions`
>    nor in the OpenAPI spec, and `payment_method` / `operator` passed anyway
>    are ignored.
>
> Thanks in advance,
> Épiphane-Gédéon — Ablony
