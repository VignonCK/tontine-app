package com.tontine.exception;

/**
 * Levée quand l'élément demandé n'existe pas (ex. : tontine ou membre
 * inconnu pour l'identifiant reçu). Affichée comme une page 404.
 *
 * RuntimeException pour les mêmes raisons que RegleMetierException :
 * pas de « throws » partout, et annulation automatique des transactions
 * @Transactional.
 */
public class RessourceIntrouvableException extends RuntimeException {

    public RessourceIntrouvableException(String message) {
        super(message);
    }
}
