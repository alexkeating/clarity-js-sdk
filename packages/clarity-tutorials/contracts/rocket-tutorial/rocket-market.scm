;;  copyright: (c) 2013-2019 by Blockstack PBC, a public benefit corporation.

;;  This file is part of Blockstack.

;;  Blockstack is free software. You may redistribute or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License or
;;  (at your option) any later version.

;;  Blockstack is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY, including without the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with Blockstack. If not, see <http://www.gnu.org/licenses/>.

;;;; Rocket-Market

;;; Storage
(define-map rockets-info
  ((rocket-id int)) 
  ((owner principal)))
(define-map rockets-count
  ((owner principal))
  ((count int)))
(define-map factory-address
  ((id int))
  ((address principal)))

;;; Internals

;; Gets the amount of rockets owned by the specified address
;; args:
;; @account (principal) the principal of the user
;; returns: int
(define (balance-of (account principal))
  (let ((balance
      (get count 
        (fetch-entry rockets-count (tuple (owner account))))))
    (if (eq? balance 'null) 0 balance)))

;; Check if the transaction has been sent by the factory-address
;; returns: boolean
(define (is-tx-from-factory)
  (let ((address
    (get address 
        (fetch-entry factory-address (tuple (id 0))))))
    (eq? tx-sender address)))

;; Gets the owner of the specified rocket ID
;; args:
;; @rocket-id (int) the id of the rocket to identify
;; returns: principal
(define (owner-of (rocket-id int)) 
  (get owner 
    (fetch-entry rockets-info (tuple (rocket-id rocket-id)))))

;;; Public functions

;; Transfers rocket to a specified principal
;; Once owned, users can trade their rockets on any unregulated black market
;; args:
;; @recipient (principal) the principal of the new owner of the rocket
;; @rocket-id (int) the id of the rocket to trade
;; returns: boolean
(define-public (transfer (recipient principal) (rocket-id int))
  (let ((balance-sender (balance-of tx-sender)))
    (let ((balance-recipient (balance-of recipient)))
      (if (and 
            (eq? (owner-of rocket-id) tx-sender)
            (> balance-sender 0)
            (not (eq? recipient tx-sender)))
        (begin
          (set-entry! rockets-info 
            (tuple (rocket-id rocket-id))
            (tuple (owner recipient))) 
          (set-entry! rockets-count 
            (tuple (owner recipient))
            (tuple (count (+ balance-recipient 1)))) 
          (set-entry! rockets-count 
            (tuple (owner tx-sender))
            (tuple (count (- balance-sender 1))))
          'true)
        'false))))

;; Mint new rockets
;; This function can only be called by the factory.
;; args:
;; @owner (principal) the principal of the owner of the new rocket
;; @rocket-id (int) the id of the rocket to mint
;; @size (int) the size of the rocket to mint
;; returns: boolean
(define-public (mint! (owner principal) (rocket-id int) (size int))
  (if (is-tx-from-factory)
    (let ((current-balance (balance-of owner)))
        (begin
        (insert-entry! rockets-info 
            (tuple (rocket-id rocket-id))
            (tuple (owner owner))) 
        (set-entry! rockets-count 
            (tuple (owner owner))
            (tuple (count (+ 1 current-balance)))) 
        'true))
    'false))

;; Set Factory
;; This function can only be called once.
;; args:
;; returns: boolean
(define-public (set-factory)
  (let ((address
      (get address 
        (fetch-entry factory-address (tuple (id 0))))))
    (if (eq? address 'null) 
        (insert-entry! factory-address 
          (tuple (id 0))
          (tuple (address tx-sender)))
        'false)))

