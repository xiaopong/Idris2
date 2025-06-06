module Data.Nat.Factor

import Syntax.PreorderReasoning
import Control.WellFounded
import Data.Fin
import Data.Fin.Extra
import Data.Nat
import Data.Nat.Order.Properties
import Data.Nat.Equational
import Data.Nat.Division

%default total

||| Factor n p is a witness that p is indeed a factor of n,
||| i.e. there exists a q such that p * q = n.
public export
data Factor : Nat -> Nat -> Type where
    CofactorExists : {p, n : Nat} -> (q : Nat) -> n = p * q -> Factor p n

||| NotFactor n p is a witness that p is NOT a factor of n,
||| i.e. there exist a q and an r, greater than 0 but smaller than p,
||| such that p * q + r = n.
public export
data NotFactor : Nat -> Nat -> Type where
    ZeroNotFactorS : (n : Nat) -> NotFactor Z (S n)
    ProperRemExists : {p, n : Nat} -> (q : Nat) ->
        (r : Fin (pred p)) ->
        n = p * q + S (finToNat r) ->
        NotFactor p n

||| DecFactor n p is a result of the process which decides
||| whether or not p is a factor on n.
public export
data DecFactor : Nat -> Nat -> Type where
    ItIsFactor : Factor p n -> DecFactor p n
    ItIsNotFactor : NotFactor p n -> DecFactor p n

||| CommonFactor n m p is a witness that p is a factor of both n and m.
public export
data CommonFactor : Nat -> Nat -> Nat -> Type where
    CommonFactorExists : {a, b : Nat} -> (p : Nat) -> Factor p a -> Factor p b -> CommonFactor p a b

||| GCD n m p is a witness that p is THE greatest common factor of both n and m.
||| The second argument to the constructor is a function which for all q being
||| a factor of both n and m, proves that q is a factor of p.
|||
||| This is equivalent to a more straightforward definition, stating that for
||| all q being a factor of both n and m, q is less than or equal to p, but more
||| powerful and therefore more useful for further proofs. See below for a proof
||| that if q is a factor of p then q must be less than or equal to p.
public export
data GCD : Nat -> Nat -> Nat -> Type where
    MkGCD : {a, b, p : Nat} ->
        {auto notBothZero : NotBothZero a b} ->
        (Lazy (CommonFactor p a b)) ->
        ((q : Nat) -> CommonFactor q a b -> Factor q p) ->
        GCD p a b


Uninhabited (Factor Z (S n)) where
    uninhabited (CofactorExists q prf) = uninhabited prf

||| Given a statement that p is factor of n, return its cofactor.
export
cofactor : Factor p n -> (q : Nat ** Factor q n)
cofactor (CofactorExists q prf) =
        (q ** CofactorExists p $ rewrite multCommutative q p in prf)

||| 1 is a factor of any natural number.
export
oneIsFactor : (n : Nat) -> Factor 1 n
oneIsFactor Z = CofactorExists Z Refl
oneIsFactor (S k) = CofactorExists (S k) (rewrite plusZeroRightNeutral k in Refl)

||| 1 is the only factor of itself
export
oneSoleFactorOfOne : (a : Nat) -> Factor a 1 -> a = 1
oneSoleFactorOfOne 0 (CofactorExists _ prf) = sym prf
oneSoleFactorOfOne 1 _ = Refl
oneSoleFactorOfOne (S (S k)) (CofactorExists Z prf) =
  absurd . uninhabited $ trans prf $ multCommutative k 0
oneSoleFactorOfOne (S (S k)) (CofactorExists (S j) prf) =
  absurd . uninhabited $
    trans
      (injective prf)
      (plusCommutative j (S (j + (k * S j))))

||| Every natural number is factor of itself.
export
Reflexive Nat Factor where
  reflexive = CofactorExists 1 $ rewrite multOneRightNeutral x in Refl

||| Factor relation is transitive. If b is factor of a and c is b factor of c
||| is also a factor of a.
export
Transitive Nat Factor where
  transitive (CofactorExists qb prfAB) (CofactorExists qc prfBC) =
    CofactorExists (qb * qc) $
        rewrite prfBC in
        rewrite prfAB in
        rewrite multAssociative x qb qc in
        Refl

export
Preorder Nat Factor where

multOneSoleNeutral : (a, b : Nat) -> S a = S a * b -> b = 1
multOneSoleNeutral Z b prf =
        rewrite sym $ plusZeroRightNeutral b in
        sym prf
multOneSoleNeutral (S k) Z prf =
        absurd . uninhabited $ trans prf $ multCommutative k 0
multOneSoleNeutral (S k) (S Z) prf = Refl
multOneSoleNeutral (S k) (S (S j)) prf =
        absurd . uninhabited .
        subtractEqLeft k {c = S j + S (j + (k * S j))} $
        rewrite plusSuccRightSucc j (S (j + (k * S j))) in
        rewrite plusZeroRightNeutral k in
        rewrite plusAssociative k j (S (S (j + (k * S j)))) in
        rewrite sym $ plusCommutative j k in
        rewrite sym $ plusAssociative j k (S (S (j + (k * S j)))) in
        rewrite sym $ plusSuccRightSucc k (S (j + (k * S j))) in
        rewrite sym $ plusSuccRightSucc k (j + (k * S j)) in
        rewrite plusAssociative k j (k * S j) in
        rewrite plusCommutative k j in
        rewrite sym $ plusAssociative j k (k * S j) in
        rewrite sym $ multRightSuccPlus k (S j) in
        injective $ injective prf

||| If a is a factor of b and b is a factor of a, then a = b.
public export
Antisymmetric Nat Factor where
  antisymmetric {x = Z} (CofactorExists _ prfAB) _ = sym prfAB
  antisymmetric {y = Z} _ (CofactorExists _ prfBA) = prfBA
  antisymmetric {x = S a} {y = S _} (CofactorExists qa prfAB) (CofactorExists qb prfBA) =
      let qIs1 = multOneSoleNeutral a (qa * qb) $
              rewrite multAssociative (S a) qa qb in
              rewrite sym prfAB in
              prfBA
      in
      rewrite prfAB in
      rewrite oneSoleFactorOfOne qa . CofactorExists qb $ sym qIs1 in
      rewrite multOneRightNeutral a in
      Refl

PartialOrder Nat Factor where

||| No number can simultaneously be and not be a factor of another number.
export
factorNotFactorAbsurd : Factor p n -> Not (NotFactor p n)
factorNotFactorAbsurd (CofactorExists _ prf) (ZeroNotFactorS _) =
        uninhabited prf
factorNotFactorAbsurd (CofactorExists q prf) (ProperRemExists q' r contra) with (cmp q q')
    factorNotFactorAbsurd (CofactorExists q prf) (ProperRemExists (q + S d) r contra) | CmpLT d =
        SIsNotZ .
        subtractEqLeft (p * q) {b = S ((p * S d) + finToNat r)} $
        rewrite plusZeroRightNeutral (p * q) in
        rewrite plusSuccRightSucc (p * S d) (finToNat r) in
        rewrite plusAssociative (p * q) (p * S d) (S (finToNat r)) in
        rewrite sym $ multDistributesOverPlusRight p q (S d) in
        rewrite sym contra in
        rewrite sym prf in
        Refl
    factorNotFactorAbsurd (CofactorExists q prf) (ProperRemExists q r contra) | CmpEQ =
      SIsNotZ $ sym $
        plusLeftCancel (p * q) 0 (S (finToNat r)) $
          trans (plusZeroRightNeutral (p * q)) $
            trans (sym prf) contra
    factorNotFactorAbsurd (CofactorExists (q + S d) prf) (ProperRemExists q r contra) | CmpGT d =
        let srEQpPlusPD = the (p + (p * d) = S (finToNat r)) $
                rewrite sym $ multRightSuccPlus p d in
                subtractEqLeft (p * q) $
                    rewrite sym $ multDistributesOverPlusRight p q (S d) in
                    rewrite sym contra in
                    sym prf
        in
        case p of
            Z => uninhabited srEQpPlusPD
            (S k) =>
                succNotLTEzero .
                subtractLteLeft k {b = S (d + (k * d))} $
                rewrite sym $ plusSuccRightSucc k (d + (k * d)) in
                rewrite plusZeroRightNeutral k in
                rewrite srEQpPlusPD in
                elemSmallerThanBound r

||| Anything is a factor of 0.
export
anythingFactorZero : (a : Nat) -> Factor a 0
anythingFactorZero a = CofactorExists 0 (sym $ multZeroRightZero a)

||| For all natural numbers p and q, p is a factor of (p * q).
export
multFactor : (p, q : Nat) -> Factor p (p * q)
multFactor p q = CofactorExists q Refl

||| If n > 0 then any factor of n must be less than or equal to n.
export
factorLteNumber : Factor p n -> {auto positN : LTE 1 n} -> LTE p n
factorLteNumber (CofactorExists Z prf) =
        let nIsZero = trans prf $ multCommutative p 0
            oneLteZero = replace {p = LTE 1} nIsZero positN
        in
        absurd $ succNotLTEzero oneLteZero
factorLteNumber (CofactorExists (S k) prf) =
        rewrite prf in
        leftFactorLteProduct p k

||| If p is a factor of n, then it is also a factor of (n + p).
export
plusDivisorAlsoFactor : Factor p n -> Factor p (n + p)
plusDivisorAlsoFactor (CofactorExists q prf) =
        CofactorExists (S q) $
            rewrite plusCommutative n p in
            rewrite multRightSuccPlus p q in
            cong (plus p) prf

||| If p is NOT a factor of n, then it also is NOT a factor of (n + p).
export
plusDivisorNeitherFactor : NotFactor p n -> NotFactor p (n + p)
plusDivisorNeitherFactor (ZeroNotFactorS k) =
        rewrite plusZeroRightNeutral k in
        ZeroNotFactorS k
plusDivisorNeitherFactor (ProperRemExists q r remPrf) =
        ProperRemExists (S q) r $
            rewrite multRightSuccPlus p q in
            rewrite sym $ plusAssociative p (p * q) (S $ finToNat r) in
            rewrite plusCommutative p ((p * q) + S (finToNat r)) in
            rewrite remPrf in
            Refl

||| If p is a factor of n, then it is also a factor of any multiply of n.
export
multNAlsoFactor : Factor p n -> (a : Nat) -> {auto aok : LTE 1 a} -> Factor p (n * a)
multNAlsoFactor _ Z = absurd $ succNotLTEzero aok
multNAlsoFactor (CofactorExists q prf) (S a) =
        CofactorExists (q * S a) $
            rewrite prf in
            sym $ multAssociative p q (S a)

||| If p is a factor of both n and m, then it is also a factor of their sum.
export
plusFactor : Factor p n -> Factor p m -> Factor p (n + m)
plusFactor (CofactorExists qn prfN) (CofactorExists qm prfM) =
        rewrite prfN in
        rewrite prfM in
        rewrite sym $ multDistributesOverPlusRight p qn qm in
        multFactor p (qn + qm)

||| If p is a factor of a sum (n + m) and a factor of n, then it is also
||| a factor of m. This could be expressed more naturally with minus, but
||| it would be more difficult to prove, since minus lacks certain properties
||| that one would expect from decent subtraction.
export
minusFactor : {b : Nat} -> Factor p (a + b) -> Factor p a -> Factor p b
minusFactor (CofactorExists qab prfAB) (CofactorExists qa prfA) =
        CofactorExists (minus qab qa) $
            rewrite multDistributesOverMinusRight p qab qa in
            rewrite sym prfA in
            rewrite sym prfAB in
            replace {p = \x => b = minus (a + b) x} (plusZeroRightNeutral a) $
            rewrite plusMinusLeftCancel a b 0 in
            rewrite minusZeroRight b in
            Refl

||| If p is a common factor of n and mod m n, then it is also a factor of m.
export
modFactorAlsoFactorOfDivider : {m, n, p : Nat} -> {auto 0 nNotZ : NonZero n} -> Factor p n -> Factor p (modNatNZ m n nNotZ) -> Factor p m
modFactorAlsoFactorOfDivider (CofactorExists qn prfN) (CofactorExists qModMN prfModMN) =
  CofactorExists (qModMN + divNatNZ m n nNotZ * qn) $ Calc $
    |~ m
    ~~ modNatNZ m n nNotZ + divNatNZ m n nNotZ * n ...(DivisionTheorem m n nNotZ nNotZ)
    ~~ qModMN * p + divNatNZ m n nNotZ * (qn * p)
              ...(rewrite multCommutative qModMN p in
                  rewrite multCommutative qn p in
                  cong2 (+) prfModMN $ cong ((*) (divNatNZ m n nNotZ)) prfN)
    ~~ qModMN * p + (divNatNZ m n nNotZ * qn) * p
              ...(cong ((+) (qModMN * p)) $ multAssociative (divNatNZ m n nNotZ) qn p)
    ~~ (qModMN + divNatNZ m n nNotZ * qn) * p ...(sym $ multDistributesOverPlusLeft qModMN _ p)
    ~~ p * (qModMN + divNatNZ m n nNotZ * qn) ...(multCommutative _ p)

||| If p is a common factor of m and n, then it is also a factor of their mod.
export
commonFactorAlsoFactorOfMod : {0 m, n, p : Nat} -> {auto 0 nNotZ : NonZero n} -> Factor p m -> Factor p n -> Factor p (modNatNZ m n nNotZ)
commonFactorAlsoFactorOfMod (CofactorExists qm prfM) (CofactorExists qn prfN) =
  CofactorExists (qm `minus` divNatNZ (qm * p) n nNotZ * qn) $
      rewrite prfM in
      rewrite multCommutative p qm
      in Calc $
    |~ (modNatNZ (qm * p) n nNotZ)
    ~~ (qm * p `minus` divNatNZ (qm * p) n nNotZ * n) ...(modDividendMinusDivMultDivider (qm * p) n)
    ~~ (qm * p `minus` divNatNZ (qm * p) n nNotZ * (qn * p))
              ...(rewrite multCommutative qn p in
                  cong (\v => qm * p `minus` divNatNZ (qm * p) n nNotZ * v) prfN)
    ~~ (qm * p `minus` divNatNZ (qm * p) n nNotZ * qn * p)
              ...(cong (minus (qm * p)) $ multAssociative (divNatNZ (qm * p) n nNotZ) qn p)
    ~~ (qm `minus` (divNatNZ (qm * p) n nNotZ * qn)) * p
              ...(sym $ multDistributesOverMinusLeft qm (divNatNZ (qm * p) n nNotZ * qn) p)
    ~~ p * (qm `minus` (divNatNZ (qm * p) n nNotZ * qn)) ...(multCommutative _ p)

||| A decision procedure for whether of not p is a factor of n.
export
decFactor : (n, d : Nat) -> DecFactor d n
decFactor Z Z = ItIsFactor $ reflexive
decFactor (S k) Z = ItIsNotFactor $ ZeroNotFactorS k
decFactor n (S d) =
        let Fraction n (S d) q r prf = Data.Fin.Extra.divMod n (S d) in
        case r of
            FZ =>
              ItIsFactor $ CofactorExists q $
                rewrite sym prf in
                  rewrite plusCommutative (q * (S d)) 0 in
                    multCommutative q (S d)

            (FS pr) =>
                ItIsNotFactor $ ProperRemExists q pr (
                        rewrite multCommutative d q in
                        rewrite sym $ multRightSuccPlus q d in
                        sym prf
                    )

||| For all p greater than 1, if p is a factor of n, then it is NOT a factor
||| of (n + 1).
export
factNotSuccFact : {p : Nat} -> GT p 1 -> Factor p n -> NotFactor p (S n)
factNotSuccFact {p = Z} pGt1 (CofactorExists q prf) =
        absurd $ succNotLTEzero pGt1
factNotSuccFact {p = S Z} pGt1 (CofactorExists q prf) =
        absurd . succNotLTEzero $ fromLteSucc pGt1
factNotSuccFact {p = S (S k)} pGt1 (CofactorExists q prf) =
        ProperRemExists q FZ (
            rewrite sym prf in
            rewrite plusCommutative n 1 in
            Refl
        )

using (p : Nat)
  ||| The relation of common factor is symmetric, that is if p is a
  ||| common factor of n and m, then it is also a common factor of
  ||| m and n.
  public export
  Symmetric Nat (CommonFactor p) where
    symmetric (CommonFactorExists p pfx pfy) = CommonFactorExists p pfy pfx

  ||| The relation of greatest common divisor is symmetric.
  public export
  Symmetric Nat (GCD p) where
    symmetric {x = Z} {y = Z} (MkGCD _ _) impossible
    symmetric {x = S _} (MkGCD cf greatest) =
      MkGCD (symmetric cf) $ \q, cf => greatest q $ symmetric cf
    symmetric {y = S _} (MkGCD cf greatest) =
      MkGCD (symmetric cf) $ \q, cf => greatest q $ symmetric cf

||| If p is a common factor of a and b, then it is also a factor of their GCD.
||| This actually follows directly from the definition of GCD.
export
commonFactorAlsoFactorOfGCD : {p : Nat} -> Factor p a -> Factor p b -> GCD q a b -> Factor p q
commonFactorAlsoFactorOfGCD pfa pfb (MkGCD _ greatest) =
        greatest p (CommonFactorExists p pfa pfb)

||| 1 is a common factor of any pair of natural numbers.
export
oneCommonFactor : (a, b : Nat) -> CommonFactor 1 a b
oneCommonFactor a b = CommonFactorExists 1
        (CofactorExists a (rewrite plusZeroRightNeutral a in Refl))
        (CofactorExists b (rewrite plusZeroRightNeutral b in Refl))

||| Any natural number is a common factor of itself and itself.
export
selfIsCommonFactor : (a : Nat) -> {auto ok : LTE 1 a} -> CommonFactor a a a
selfIsCommonFactor a = CommonFactorExists a reflexive reflexive

gcdUnproven' : (m, n : Nat) -> (0 sizeM : SizeAccessible m) -> (0 n_lt_m : LT n m) -> Nat
gcdUnproven' m Z _ _ = m
gcdUnproven' m (S n) (Access rec) n_lt_m =
  let mod_lt_n = boundModNatNZ m (S n) ItIsSucc in
  gcdUnproven' (S n) (modNatNZ m (S n) ItIsSucc) (rec _ n_lt_m) mod_lt_n

||| Total definition of the gcd function. Does not return GСD evidence, but is faster.
gcdUnproven : Nat -> Nat -> Nat
gcdUnproven m n with (isLT n m)
  gcdUnproven m n | Yes n_lt_m = gcdUnproven' m n (wellFounded m) n_lt_m
  gcdUnproven m n | No not_n_lt_m with (decomposeLte m n $ notLTImpliesGTE not_n_lt_m)
    gcdUnproven m n | No not_n_lt_m | Left m_lt_n = gcdUnproven' n m (wellFounded n) m_lt_n
    gcdUnproven m n | No not_n_lt_m | Right m_eq_n = m

gcdUnproven'Greatest : {m, n, c : Nat} -> (0 sizeM : SizeAccessible m) -> (0 n_lt_m : LT n m)
  -> Factor c m -> Factor c n -> Factor c (gcdUnproven' m n sizeM n_lt_m)
gcdUnproven'Greatest {n = Z} _ _ cFactM _ = cFactM
gcdUnproven'Greatest {n = S n} (Access rec) n_lt_m cFactM cFactN =
  gcdUnproven'Greatest (rec _ n_lt_m) (boundModNatNZ m (S n) ItIsSucc) cFactN (commonFactorAlsoFactorOfMod cFactM cFactN)

gcdUnprovenGreatest : (m, n : Nat) -> {auto 0 ok : NotBothZero m n} -> (q : Nat) -> CommonFactor q m n -> Factor q (gcdUnproven m n)
gcdUnprovenGreatest m n q (CommonFactorExists q qFactM qFactN) with (isLT n m)
  gcdUnprovenGreatest m n q (CommonFactorExists q qFactM qFactN) | Yes n_lt_m
    = gcdUnproven'Greatest (sizeAccessible m) n_lt_m qFactM qFactN
  gcdUnprovenGreatest m n q (CommonFactorExists q qFactM qFactN) | No not_n_lt_m with (decomposeLte m n $ notLTImpliesGTE not_n_lt_m)
    gcdUnprovenGreatest m n q (CommonFactorExists q qFactM qFactN) | No not_n_lt_m | Left m_lt_n
      = gcdUnproven'Greatest (sizeAccessible n) m_lt_n qFactN qFactM
    gcdUnprovenGreatest Z Z q (CommonFactorExists q qFactM qFactN) | No not_n_lt_m | Right m_eq_n impossible
    gcdUnprovenGreatest (S m) (S n) q (CommonFactorExists q qFactM qFactN) | No not_n_lt_m | Right m_eq_n = qFactM

gcdUnproven'CommonFactor : {m, n : Nat} -> (0 sizeM : SizeAccessible m) -> (0 n_lt_m : LT n m) -> CommonFactor (gcdUnproven' m n sizeM n_lt_m) m n
gcdUnproven'CommonFactor {n = Z} _ _ = CommonFactorExists _ reflexive (anythingFactorZero m)
gcdUnproven'CommonFactor {n = S n} (Access rec) n_lt_m with (gcdUnproven'CommonFactor (rec _ n_lt_m) (boundModNatNZ m (S n) ItIsSucc))
  gcdUnproven'CommonFactor (Access rec) n_lt_m | (CommonFactorExists _ factM factN)
    = CommonFactorExists _ (modFactorAlsoFactorOfDivider factM factN) factM

gcdUnprovenCommonFactor : (m, n : Nat) -> {auto 0 ok : NotBothZero m n} -> CommonFactor (gcdUnproven m n) m n
gcdUnprovenCommonFactor m n with (isLT n m)
  gcdUnprovenCommonFactor m n | Yes n_lt_m = gcdUnproven'CommonFactor (sizeAccessible m) n_lt_m
  gcdUnprovenCommonFactor m n | No not_n_lt_m with (decomposeLte m n $ notLTImpliesGTE not_n_lt_m)
    gcdUnprovenCommonFactor m n | No not_n_lt_m | Left m_lt_n = symmetric $ gcdUnproven'CommonFactor (sizeAccessible n) m_lt_n
    gcdUnprovenCommonFactor Z Z | No not_n_lt_m | Right m_eq_n impossible
    gcdUnprovenCommonFactor (S m) (S n) | No not_n_lt_m | Right m_eq_n = rewrite m_eq_n in selfIsCommonFactor (S n)

||| An implementation of Euclidean Algorithm for computing greatest common
||| divisors. It is proven correct and total; returns a proof that computed
||| number actually IS the GCD.
export
gcd : (a, b : Nat) -> {auto ok : NotBothZero a b} -> (f : Nat ** GCD f a b)
gcd a b = (_ ** MkGCD (gcdUnprovenCommonFactor a b) (gcdUnprovenGreatest a b))

||| For every two natural numbers there is a unique greatest common divisor.
export
gcdUnique : GCD p a b -> GCD q a b -> p = q
gcdUnique (MkGCD pCFab greatestP) (MkGCD qCFab greatestQ) =
    antisymmetric (greatestQ p pCFab) (greatestP q qCFab)

divByGcdHelper : (a, b, c : Nat) -> GCD (S a) (S a * S b) (S a * c) -> GCD 1 (S b) c
divByGcdHelper a b c (MkGCD _ greatest) =
    MkGCD (CommonFactorExists 1 (oneIsFactor (S b)) (oneIsFactor c)) $
    \q, (CommonFactorExists q (CofactorExists qb prfQB) (CofactorExists qc prfQC)) =>
        let qFab = CofactorExists qb $
                rewrite multCommutative q (S a) in
                rewrite sym $ multAssociative (S a) q qb in
                rewrite sym $ prfQB in
                Refl
            qFac = CofactorExists qc $
                rewrite multCommutative q (S a) in
                rewrite sym $ multAssociative (S a) q qc in
                rewrite sym $ prfQC in
                Refl
            CofactorExists f prfQAfA =
                greatest (q * S a) (CommonFactorExists (q * S a) qFab qFac)
            qf1 = multOneSoleNeutral a (f * q) $
                rewrite multCommutative f q in
                rewrite multAssociative (S a) q f in
                rewrite sym $ multCommutative q (S a) in
                prfQAfA
        in
        CofactorExists f $
            rewrite multCommutative q f in
            sym qf1

||| For every two natural numbers, if we divide both of them by their GCD,
||| the GCD of resulting numbers will always be 1.
export
divByGcdGcdOne : {a, b, c : Nat} -> GCD a (a * b) (a * c) -> GCD 1 b c
divByGcdGcdOne {a = Z} (MkGCD _ _) impossible
divByGcdGcdOne {a = S a} {b = Z} {c = Z} (MkGCD {notBothZero} _ _) =
        case replace {p = \x => NotBothZero x x} (multZeroRightZero (S a)) notBothZero of
            LeftIsNotZero impossible
            RightIsNotZero impossible
divByGcdGcdOne {a = S a} {b = Z} {c = S c} gcdPrf@(MkGCD {notBothZero} _ _) =
        case replace {p = \x => NotBothZero x (S a * S c)} (multZeroRightZero (S a)) notBothZero of
            LeftIsNotZero impossible
            RightIsNotZero => symmetric $ divByGcdHelper a c Z $ symmetric gcdPrf
divByGcdGcdOne {a = S a} {b = S b} {c = Z} gcdPrf@(MkGCD {notBothZero} _ _) =
        case replace {p = \x => NotBothZero (S a * S b) x} (multZeroRightZero (S a)) notBothZero of
            RightIsNotZero impossible
            LeftIsNotZero => divByGcdHelper a b Z gcdPrf
divByGcdGcdOne {a = S a} {b = S b} {c = S c} gcdPrf =
        divByGcdHelper a b (S c) gcdPrf
