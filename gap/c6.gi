#############################################################################
##
##  c6.gi
##                                recog package
##                                                        Max Neunhoeffer
##                                                            Ákos Seress
##
##  Copyright 2005-2008 by the authors.
##  This file is free software, see license information at the end.
##
## This implementation is probably based on the paper
## 'A reduction algorithm for matrix groups with an extraspecial normal subgroup.'
## by
## Brooksbank, Peter; Niemeyer, Alice C.; Seress, Ákos
## in
## Finite geometries, groups, and computation, 1–16, Walter de Gruyter GmbH & Co. KG, Berlin, 2006.
##
##  Find a subgroup of the normaliser of a symplectic type r group
##
#############################################################################


#    functions related to coordinatization of a group R,
#    where R/Z(R) is a vector space

#    basis(r,n,q,gr)
#    the input gr is the extraspecial group or a subgroup corresponding
#    to a NONSINGULAR subspace (important, otherwise fails), plus possibly
#    scalar matrices
#    output: a list of 4k matrices; the first 2k are generators for gr
#    corresponding to a basis e_1,f_1,...,e_k,f_k of hyperbolic pairs for odd r,
#    and noncommuting pairs for r=2 (in the full extraspecial group k=n);
#    the other 2k matrices contain
#    basis vectors for the eigenspaces of the generators
#
#    exponents(r,n,q,list,x)
#    list must be the output of ``basis''
#    x is an arbitrary element of the extraspecial
#    output: a list of 2k numbers, containing the exponents in the
#    decomposition x=e_1^(a_1) f_1^(b_1) e_2^(a_2) ... f_k^(b_k) z^l
#    (here z is a scalar; its exponent is not computed because we do not
#    need it)
#
#    rewriteones(r,n,q,list,x)
#    list must be the output of ``basis''
#    x is an element of the normalizer of the extraspecial in GL(r^n,q)
#    output: 2k x 2k matrix over GF(r), corresponding to the action of x
#    on the symplectic space, in the basis e_1,f_1,...,f_k




# given the eigenspaces of a hyperbolic pair of group elements
# (or a noncommuting pair in the case r=2) from a basis and
# another group element x, it finds the powers of the basis elements in x
RECOG.whichpower:=function(r,n,q,spa,spb,x)
    local v,w,i,j;

    v:=spa[1]*x;
    w:=SolutionMat(spa,v);
    j:=Position(List(w,y->y<>0*Z(q)),true);
    j:=Int( (j-1)/r ^(n-1));

    v:=spb[1]*x;
    w:=SolutionMat(spb,v);
    i:=Position(List(w,y->y<>0*Z(q)),true);
    i:=Int( (i-1)/r ^(n-1));

    return [i,j];
end;

# blocks is a block system of r subspaces, basis for subspaces listed
# in one big list; x permutes the subspaces
# computes the permutation action of x
# ell is the number of blocks
RECOG.ActionOnBlocks := function(r,n,q,blks,x)

    local w,i,j,perm, ell, blocks;

    ell := blks.ell;
    blocks := blks.blocks * x * blks.blocks^-1;
    perm:=[];
    for i in [1..ell] do
      w:=blocks[1+(i-1)*(Length(blocks)/ell)];
      j:=Position(List(w,y->y<>0*Z(q)),true);
      j:=1+Int( (j-1)/(Length(blocks)/ell));
      perm[i]:=j;
    od;

    return PermList(perm);
end;

RECOG.HomFuncActionOnBlocks := function(data,el)
  return RECOG.ActionOnBlocks(data.r,data.n,data.q,data.blks,el);
end;


RECOG.CommonDiagonal2:=function(r,n,q,rad)
    local xxx,newq,es,nicebasis,blocksizes,i,mat,sum,newblocksizes,newnicebasis,
          x,y,size;

    Info(InfoRecog,3,"C6: enter new diagonalization");
    xxx:=Runtime();

    if r=2 and (q mod 4) =3 then
       newq:=q^2;
    else
       newq:=q;
    fi;
    es:=Eigenspaces(GF(newq),rad[1]);
    nicebasis:=Concatenation(List(es,x->GeneratorsOfVectorSpace(x)));
    MakeImmutable(nicebasis);
    blocksizes:=List(es,x->Dimension(x));
    for i in [2..Length(rad)] do
      if Length(blocksizes) < r^n then
        mat:=nicebasis*rad[i]/nicebasis;
        sum:=0;
        newblocksizes:=[];
        newnicebasis:=[];
        for size in blocksizes do
          if size = 1 then
            Add(newnicebasis,Concatenation(List([1..sum],x->Zero(GF(newq))),
              [One(GF(newq))],List([sum+2..r^n],x->Zero(GF(newq)))));
            sum:=sum+1;
            Add(newblocksizes,1);
          else
            es:=Eigenspaces(GF(newq),mat{[sum+1..sum+size]}{[sum+1..sum+size]});
            for x in es do
              for y in GeneratorsOfVectorSpace(x) do
                Add(newnicebasis,Concatenation(List([1..sum],x->Zero(GF(newq))),
                    y,List([sum+size+1..r^n],x->Zero(GF(newq)))));
              od;
            od;
            Append(newblocksizes,List(es,x->Dimension(x)));
            sum:=sum+size;
          fi;
        od;
        MakeImmutable(newnicebasis);
        nicebasis:=newnicebasis*nicebasis;
        blocksizes:=newblocksizes;
      fi;
    od;

    Info(InfoRecog,3,Runtime()-xxx,"exit new diagonalization");

    return nicebasis;
end;


#for a list of commuting, noncentral elements of the extraspecial group
#times scalars, computes a basis of the vectorspace generated by them
#nicebasis is an r^n x r^n matrix, conjugating the input into diagonal form
#the vector space is a subspace of GF(r)^(r^n)
RECOG.RadBasis:=function(r,n,q,rad)
    local s, i, nicebasis, niceinv, diagrad,  action, blocks, f, xxx, xxy;

    Info(InfoRecog,3,"Reached Radbasis");
    if Length(rad)=0 then
       return [ [],[],[],[] ];
    fi;

    nicebasis := RECOG.CommonDiagonal2(r,n,q,rad);
    niceinv := nicebasis^(-1);
    Info(InfoRecog,3,"checking diagonalization:  ",
         Collected(List(rad,x->IsDiagonalMat(nicebasis*x*niceinv))));
    diagrad:=List(rad,x->DiagonalOfMat(nicebasis*x*niceinv));

    #write each vector in diagrad as scalar times a vector over GF(r)
    action:= [];
    for i in [1..Length(diagrad)] do
        action[i]:=List(diagrad[i],x-> x/diagrad[i][1]);
    od;
        action := TransposedMatMutable(action);

if Length(action) <> Length(nicebasis) then
    Error("what's wrong?");
fi;

    # The identical rows of action correspond to vectors in
    # a  homogeneous component
    s := Set( action );

if Length(nicebasis) mod Length(s)  <> 0 then
    Error("what's wrong2?");
fi;
    # all vectors in nicebasis whose rows in action are
    # identical form a block
    f := function (a, b) return Position(s,a) <= Position(s,b); end;
    blocks := ShallowCopy(nicebasis);
    SortParallel( action, blocks, f );

    Info(InfoRecog,3,"Radbasis end");

    return rec( ell := Length(s) , blocks := blocks );

end;


#creates a basis for a subgroup g of the extraspecial group
RECOG.basis2:=function(r,n,q,g)
    local xxx,
    a,b,spa,i,j,k,len,gens,list,list2,spb,ainv,binv,powers,posa,rad,
          posb,newq;

    xxx:=Runtime();
    Info(InfoRecog,3,"enter basis2");

    #need a field where characteristic polynomials split into linear factors
    if r=2 and (q mod 4) = 3 then
       newq:=q^2;
    else
       newq:=q;
    fi;

    list  := []; # will contain the generators for the nonsingular part
    list2 := []; # will contain the eigenspace bases for the generators
    rad   := []; # will contain generators for the radical
    len   := Length(GeneratorsOfGroup(g));
    gens  := [];
    for i in [1..len] do
      Add(gens,GeneratorsOfGroup(g)[i]);
    od;

    repeat
       posa:=0;
       posb:=0;
       k:=1;

       repeat
          if IsBound(gens[k]) then
             if gens[k]<>gens[k][1,1]*One(g) then
                a:=gens[k];
                posa:=k;
             else
                k:=k+1;
             fi;
             Unbind(gens[k]);
          else
             k:=k+1;
          fi;
       until posa > 0 or k > len;
       if posa > 0 then
          k:=k+1;
          repeat
            if IsBound(gens[k]) then
               if gens[k] = gens[k][1,1]*One(g) then
                  Unbind(gens[k]);
                  k:=k+1;
               elif gens[k]*a <> a*gens[k] then
                  b:=gens[k];
                  Unbind(gens[k]);
                  posb:=k;
               else
                  k:=k+1;
               fi;
            else
                k:=k+1;
            fi;
          until posb > 0 or k > len;

          if posb > 0 then # found a hyperbolic pair
             Add(list,a);
             Add(list,b);
             spa := Eigenspaces(GF(newq),a)[1];
             spa := List(GeneratorsOfVectorSpace(spa),z->ShallowCopy(z));
             #list bases for other eigenspaces, in the order b permutes them
                     for i in [1..r-1] do
                        for j in [1..r^(n-1)] do
                           spa[i*r^(n-1)+j]:=spa[(i-1)*r^(n-1)+j]*b;
                        od;
                     od;
                     MakeImmutable(spa);
                     Add(list2,spa);

             spb := Eigenspaces(GF(newq),b)[1];
             spb := List(GeneratorsOfVectorSpace(spb),z->ShallowCopy(z));
             for i in [1..r-1] do
                for j in [1..r^(n-1)] do
                   spb[i*r^(n-1)+j]:=spb[(i-1)*r^(n-1)+j]*a;
                od;
             od;
             MakeImmutable(spb);
             Add(list2,spb);

             ainv:=a^(-1);
             binv:=b^(-1);

             for j in [1..len] do
                if IsBound(gens[j]) then
                   powers:=RECOG.whichpower(r,n,q,spa,spb,gens[j]);
                   gens[j]:=gens[j]*(ainv^powers[1])*(binv^powers[2]);
                fi;
             od;
          else # a commutes with everybody
             Add(rad,a);
          fi;
      fi; # posa > 0
    until posa=0;

    Info(InfoRecog,3,"exit basis2");

    if Length(rad) > 0 then
        return rec( basis := rec(), blocks := RECOG.RadBasis(r,n,q,rad) );
    else
        return rec( basis := rec(sympl:=list,es:=list2), blocks := [] );
    fi;

end;


# given the symplectic basis and a group element x, it finds the
# exponents of the symplectic basis elements in the decomposition of x
RECOG.exponents:=function(r,n,q,list2,x)
    local i,len,exp,pair;

    exp:=[];
    len:=Length(list2)/2;
    for i in [1..len] do
      pair:=RECOG.whichpower(r,n,q,list2[2*i-1],list2[2*i],x);
      Add(exp,pair[1]);
      Add(exp,pair[2]);
    od;

    return exp;
end;

# divides out the hyperbolic pair part of the bottom group
# should return something in the radical
RECOG.check:=function(r,n,q,list,x,exp)
    local y,i;

    #Print(exp, "\n");

    y:=One(x);
    for i in [1..Length(list)] do
      y:=y*list[i]^exp[i];
    od;

    return (x/y);
end;

#divides out the radical part of the bottom group
#should return a scalar matrix
RECOG.check2 := function(r,n,q,rad,x,coeffs)

    local y,i;

    #Print(List( coeffs, i-> IntFFE(i)), "\n" );

    y := One(x);
    for i in [1..Length(rad)] do
      y := y*rad[i]^IntFFE(coeffs[i]);
    od;

    return (x/y);
end;


# rewrite an element of the normalizer of the extraspecial group
# as 2n x 2n matrix over GF(r) (or as smaller matrix, if the
# extraspecial group is just a subgroup of r^(1+2n) )

RECOG.rewriteones := function(r,n,q,data,blocks,x)

    local list,rad, mat, i, xx, exp, remain, remain2, coeffs;

    if blocks = [] then
        list  := data.sympl;
        mat   := [];
        for i in [1..Length(list)] do
            xx := list[i]^x;
            exp := RECOG.exponents(r,n,q,data.es,xx);
            remain := RECOG.check(r,n,q,list,xx,exp);
            if remain <> remain[1,1]*One(remain) then
                return fail;
            fi;
            Add(mat, Z(r)^0*exp);
        od;
        return mat;
    else #we are in type 3 output
        return RECOG.ActionOnBlocks(r,n,q,blocks,x);
    fi;
end;

RECOG.HomFuncrewriteones := function(da,el)
  return RECOG.rewriteones(da.r,da.n,da.q,da.data,[],el);
end;


#   these functions were added by me to help test when
#   an element of the normaliser powers up to a noncentral
#   element of R.

#finds the multiplicity of x-1 in x^n-1 factored over GF(p)
RECOG.multiplicity:=function(p,n)
    local  f, one, x, facs, l, i;

   f:=GF(p);
   one:=One(f);
   x:=X(f);
   facs:=Collected( Factors(x^n-one) );
   l:=Length(facs);
   i:=0;
   repeat
      i:=i+1;
   until facs[i][1]=x-one;

   return facs[i][2];
end;

# decompose a vector space into a sum of common eigenspaces
# rad is generator list for an abelian matrix group
RECOG.commondiagonal:=function(q,rad)
    local xxx, int, es, int2, vs, nicebasis, i, j, k;

    Info(InfoRecog,3,"enter diagonalization");

    int:=Eigenspaces(GF(q^2),rad[1]);
    for i in [2..Length(rad)] do
        es:=Eigenspaces(GF(q^2),rad[i]);
        int2:=[];
        for j in [1..Length(int)] do
            for k in [1..Length(es)] do
                vs:=Intersection(int[j],es[k]);
                if Dimension(vs)>0 then
                   Add(int2,vs);
                fi;
            od;
        od;
        int:=int2;
    od;
    nicebasis:=Concatenation(List(int,x->GeneratorsOfVectorSpace(x)));
    MakeImmutable(nicebasis);

    Info(InfoRecog,3,"exit diagonalization");
    return nicebasis;
end;

#creates a basis for a subgroup g of the extraspecial group
RECOG.basis:=function(r,n,q,g)
    local xxx,
    a,b,spa,i,j,k,len,gens,list,list2,spb,ainv,binv,powers,posa,rad,
          radoutput;

    Info(InfoRecog,3,"enter basis");


    list:=[]; #this will contain the generators for the nonsingular part
    list2:=[]; #this will contain the eigenspace bases for the generators
    rad:=[]; #this will contain generators for the radical
    len:=Length(GeneratorsOfGroup(g));
    gens:=[];
    for i in [1..len] do
      Add(gens,GeneratorsOfGroup(g)[i]);
    od;
    Add(gens,One(gens[1]));
    len:=len+1;

    repeat
      k:=0;

      repeat
        k:=k+1;
        a:=gens[k];
      until a<>a[1,1]*One(a) or k=len;
      posa:=k;
      if k<len then
        repeat
           k:=k+1;
           b:=gens[k];
        until a*b <> b*a or k=len;
      fi;
      if k<len then #we found a hyperbolic pair
        Add(list,a);
        Add(list,b);

        spa:=Eigenspaces(GF(q^2),a)[1];
        spa:=List(GeneratorsOfVectorSpace(spa),z->ShallowCopy(z));
        #list bases for other eigenspaces, in the order b permutes them
        for i in [1..r-1] do
          for j in [1..r^(n-1)] do
            spa[i*r^(n-1)+j]:=spa[(i-1)*r^(n-1)+j]*b;
          od;
        od;
        MakeImmutable(spa);
        Add(list2,spa);

        spb:=Eigenspaces(GF(q^2),b)[1];
        spb:=List(GeneratorsOfVectorSpace(spb),z->ShallowCopy(z));
        for i in [1..r-1] do
          for j in [1..r^(n-1)] do
            spb[i*r^(n-1)+j]:=spb[(i-1)*r^(n-1)+j]*a;
          od;
        od;
        MakeImmutable(spb);
        Add(list2,spb);

        ainv:=a^(-1);
        binv:=b^(-1);

        for j in [1..len] do
          powers:=RECOG.whichpower(r,n,q,spa,spb,gens[j]);
          gens[j]:=gens[j]*(ainv^powers[1])*(binv^powers[2]);
        od;
      fi;
      if k=len and posa<k then #a is in the center, but not scalar
         Add(rad,a);
         for i in [posa..len-1] do
             gens[i]:=gens[i+1];
         od;
         len:=len-1;
         k:=0;
      fi;
    until k>=len;

    radoutput := RECOG.RadBasis(r,n,q,rad);

    Info(InfoRecog,3,"exit basis");

    return rec(sympl:=list,es:=list2,nicebasis:=radoutput[1],
       niceinv:=radoutput[2], vs:=radoutput[3], rad:=radoutput[4]);

end;



RECOG.TestAbelianOld := function (n,grp,u)

    local list, x, y, limu, randlist, randgens;

        list := [u];
        if Length(GeneratorsOfGroup(grp)) > 3 then
            limu := 16 * n;
    else
        limu := 13 * n;
        fi;

    while limu > 0 do
            limu := limu - 1;
            x  := RandomSubproduct(list);
            y  := RandomSubproduct(list);
        x  := Comm(x,y);
        if x <> x[1,1] * One(x) then
        return [false,x];
        fi;
            randlist:= RandomSubproduct(list);
            if randlist <> One(grp) then
                if Length(GeneratorsOfGroup(grp)) > 3 then
                    randgens:= RandomSubproduct(grp);
                    if randgens <> One(grp) then
                        Add(list,randlist^randgens);
                    fi;
                else # for short generator lists, conjugate with all gens
                    for randgens in GeneratorsOfGroup(grp) do
                        Add(list, randlist^randgens);
                    od;
                fi;
            fi;
    od;

    return [true,u,list];

end;


#############################################################################
##
#F  TestAbelian(n,grp,u) . . . . . . . . . . . . . . . .
##

RECOG.TestAbelian := function (n,grp,u)

    local list, x, y, h, g, pos, limu, randlist, randgens;

    list := [u];
    limu := Maximum(16,6*n);

    while limu > 0 do
        limu := limu - 1;
        y  := RandomSubproduct(list);
        # check whether y commutes with the element computed
        # in the previous iteration
        x := list[Length(list)];
        h := x * y; g := y * x;
        pos := PositionNonZero( h[1] );
        if g <> g[1][pos]/h[1][pos]   * h then
            # x and y do not commute
             return [ false, g/h ];
        fi;

        x := y^PseudoRandom(grp);
        h := x * y; g := y * x;
        pos := PositionNonZero( h[1] );
        if g <> g[1][pos]/h[1][pos]   * h then
            # x and y do not commute
             return [ false, g/h ];
        fi;
        Add( list, x );

    od;

    return [true,u,list];

 end;



#############################################################################
##
##  fast randomised routine for testing whether <w^grp> is
##  a vector space modulo scalars
##  the input MUST have projective order r
##  2 means <w^grp>/Z(R) is a vector space of dimension > 0
##  3 means Z(R)-coset of w is fixed by grp

#############################################################################
##
#F  BlindDescent() . . . . . . . . . . . . . . . .
##

RECOG.BlindDescent := function(r,n,grp,limit)

    local x, ox, y, oy, z,  p, abel;

    x := PseudoRandom(grp);

    while limit > 0 do
        limit := limit - 1;
        y := PseudoRandom(grp);
        oy := ProjectiveOrder(y)[1];
        if oy mod r = 0  then
            abel := RECOG.TestAbelian(n,grp,y^(oy/r));
            if  abel[1] = true  then
                return [y^(oy/r),abel[3]];
            fi;
        fi;
        for p in Union(List( Collected(Factors(oy)), i->i[1]),[1]) do
            z :=Comm(x,y^(oy/p));
            if z <> z[1,1] * One(z) then
                x := z;
            fi;
        od;
        ox := ProjectiveOrder(x)[1];
        if ox  mod r = 0 then
            abel := RECOG.TestAbelian(n,grp,x^(ox/r));
            if abel[1] = true  then
                return [x^(ox/r),abel[3]];
            else
               x := abel[2];
            fi;
        else
            x :=  RECOG.TestAbelian(n,grp,x)[2];
        fi;
    od;
    return fail;
end;


#############################################################################
##
#F  RecogniseC6() . . . . . . . . . . . . . . . .
## the algorithm to recognise, constructively, when <grp> is a subgroup
## of the normaliser of symplectic type r-group.
## the output is a record having the following fields:
##  .<igens> = the image of the given gens for <grp> in the classical group
##  .<basis> = 2n gens for the r-group that <grp> normalises,
##             and a standard basis for corresponding classical module
##  .<r>     = the r for the symplectic type r-group
##  .<n>     = r^n is the dimension of <grp>
##  .<q>     = field size of given representation
## or fail to indicate (possibly temporary) failure or false to indicate
## that it failed forever, so there is no point to call it again.
RECOG.New2RecogniseC6 := function(grp)

    local   type, blocks, spaces, xxx, d, b, ppi,
            r, n, q, u, rgrp, grpbasis, igens, list, i, grp1;

    d := DimensionOfMatrixGroup(grp);
    q := Size(FieldOfMatrixGroup(grp));
    ppi := PrimePowersInt(d);
    r := ppi[1];
    n := ppi[2];
    if not Length(ppi) = 2 then
        return NeverApplicable;
    fi;
    if (q-1) mod r <> 0 then
        return NeverApplicable;
    fi;

    ## first find a non-central element of the <r>-core of <grp>
    b := RECOG.BlindDescent(r,n,grp,100);
    if b = fail then return TemporaryFailure; fi;
    Info(InfoRecog,3,"Finished blind descent");

    u := b[1];

    ## take enough conjugates to generate the <r>-core
    rgrp := Group(b[2]);
    ## try to find a set of standard gens for <rgrp>
    grpbasis := RECOG.basis2(r,n,q,rgrp);

    ## construct image of <grp> in classical group
    Info(InfoRecog,3,"enter image computation");
    igens := List(GeneratorsOfGroup(grp),
               x->RECOG.rewriteones(r,n,q,grpbasis.basis,grpbasis.blocks,x));
    Info(InfoRecog,3,"exit image computation");
    if Position(igens,fail) = fail then
        return rec( igens := igens, basis := grpbasis,
                    r := r, n := n, q := q );
    else
        return TemporaryFailure;
    fi;

end;

FindHomMethodsProjective.C6 := function(ri,G)
    local r,re,hom;

    RECOG.SetPseudoRandomStamp(G,"C6");

    re := RECOG.New2RecogniseC6(G);
    if re = TemporaryFailure or re = NeverApplicable then
        return re;
    fi;

    if re.basis.basis = rec() then
        Info(InfoRecog,2,"C6: Found block system.");
        hom := GroupHomByFuncWithData(G,GroupWithGenerators(re.igens),
                 RECOG.HomFuncActionOnBlocks,
                 rec(r := re.r,n := re.n,q := re.q,blks := re.basis.blocks));
        forkernel(ri).t := re.basis.blocks.blocks;
        forkernel(ri).blocksize := ri!.dimension / re.basis.blocks.ell;
        Add(forkernel(ri).hints,
            rec(method := FindHomMethodsProjective.DoBaseChangeForBlocks,
                rank := 2000, stamp := "DoBaseChangeForBlocks"),1);
        Setimmediateverification(ri,true);
        findgensNmeth(ri).args[1] := re.basis.blocks.ell + 3;
        findgensNmeth(ri).args[2] := 5;
        Setmethodsforfactor(ri,FindHomDbPerm);
    else
        Info(InfoRecog,2,"C6: Found homomorphism.");
        hom := GroupHomByFuncWithData(G,GroupWithGenerators(re.igens),
                 RECOG.HomFuncrewriteones,
                 rec(r := re.r,n := re.n,q := re.q,data := re.basis.basis));
        findgensNmeth(ri).args[1] := 3 + re.n;
        findgensNmeth(ri).args[2] := 5;
        Setimmediateverification(ri,true);
        Setmethodsforfactor(ri,FindHomDbMatrix);
    fi;
    SetHomom(ri,hom);

    return Success;
end;

# code prepared by Steve Linton
# see comment for main function for its description
# MakeC6Group (Sp(4, 3), Sp (4, 3), 7);

SMTX.SetInvariantBilinearForm:=function(module,b)
  module.InvariantBilinearForm:=b;
end;

#############################################################################
##
#F  InvariantBilinearForm ( module ) . . . .
##
## Look for an invariant bilinear form of the absolutely irreducible
## GModule module. Return fail, or the matrix of the form.
SMTX_InvariantBilinearForm := function ( module  )
   local DM, iso;

   if not SMTX.IsMTXModule(module) or
                            not SMTX.IsAbsolutelyIrreducible(module) then
      Error(
 "Argument of InvariantBilinearForm is not an absolutely irreducible module");
   fi;
   if IsBound(module.InvariantBilinearForm) then
     return module.InvariantBilinearForm;
   fi;
   DM := SMTX.DualModule(module);
   iso := MTX.Isomorphism(module,DM);
   if iso = fail then
       SMTX.SetInvariantBilinearForm(module, fail);
       return fail;
   fi;
   ConvertToMatrixRep(iso,module.field);
   MakeImmutable(iso);
   SMTX.SetInvariantBilinearForm(module, iso);
   return iso;
end;

SMTX.InvariantBilinearForm := SMTX_InvariantBilinearForm;

#
# Inputs are g a group of matrices preserving a symplectic form
#            over another group of matrices preserving the same symplectic form
#                 and acting absolutely irreducibly
#            p a prime
#
#            Suppose g <= over <= Sp(2k,r) this function will return a
#            group of r^k x r^k matrices in characteristic p with a
#            normal subgroup R of type r^{1+2k} preserving the set of
#            one-spaces generated by the basis and quotient isomorphic
#            to g
#
#            over is needed when g does not act absolutely
#            irreducibly, as a convenient way to specify the symplectic
#            form in question
#
#      The algorithm is based on the technique used by Walsh in
#      the construction of the Monster
#

RECOG.MakeC6Group := function(g,over,p)
    local   f,  r,  gm,  M,  k,  chis,  ws,  space,  i,  chi,  w,  x,
            basis,  newgens,  labels,  q,  zeta,  Ts,  Ds,  result,
            us,  vs,  o,  vmos,  allvs,  toprow, b, m;
    #
    # preliminaries
    #
    f := DefaultFieldOfMatrixGroup(g);
    r := Characteristic(f);
    if Size(f) <> r then
        Error("Must be over prime field");
    fi;
    if p = r then
        Error("Must be another characteristic");
    fi;
    if p =2 or r =2 then
        Error("Odd characteristics only please");
    fi;
    q := p;
    while (q-1) mod r <> 0 do
        q := q*p;
    od;
    if q > 65536 then
        Error("field too big");
    fi;
    zeta := Z(q)^((q-1)/r);
    #
    # Find the form
    #
    gm := GModuleByMats(GeneratorsOfGroup(over),f);
    M := MTX.InvariantBilinearForm(gm);
    if TransposedMat(M) <> -M then
        Error("form not symplectic");
    fi;
    #
    # Now convert that into the "standard" symplectic form
    #
    # ( 0 I)
    # (-I 0)
    #
    #  where I is a k x k identity matrix
    #
    #  chis are the basis of the first part of the space
    #  ws the basis of the second part
    #
    k := DimensionOfMatrixGroup(g)/2;
    chis := [];
    ws := [];
    #
    # space will the space orthogonal to all the chis and ws
    #
    space := FullRowSpace(f,2*k);
    for i in [1..k] do
        repeat
            chi := Random(space);
        until not IsZero(chi);
        repeat
            w := Random(space);
        until not IsZero(w) and not IsZero(chi*M*w);
        x := chi*M*w;
        if not IsOne(x) then
            w := w/x;
        fi;
        Add(chis,chi);
        Add(ws,w);
        if i <> k then
            b := GeneratorsOfLeftModule(space);
            space := Submodule(space,NullspaceMat(b*M*TransposedMat([chi,w]))*b);
        fi;
    od;
    #
    # OK, now rewrite the group so that it preserves our favourite
    # symplectic form
    #
    basis := Concatenation(chis,ws);
    newgens := List(GeneratorsOfGroup(g), x->basis*x*basis^-1);
    #
    # Now thw basis will be in bijection with F_r^k
    #
    labels := Elements(FullRowSpace(f,k));
    basis := CanonicalBasis(FullRowSpace(f,k));
    #
    # Make the 2k generators of the extra-special group, which will be
    # in bijection with our favourite symplectic basis
    #
    Ts := List([1..k], i->
                  PermutationMat(PermListList(labels, List(labels,l->l+basis[i])),r^k,GF(q)));
    Ds :=  List([1..k], i->
                DiagonalMat(List(labels,l->zeta^IntFFE(basis [i]*l))));
    MakeImmutable(Ts);
    MakeImmutable(Ds);
    result := Concatenation(Ts,Ds);
    for m in result do
        ConvertToMatrixRep(m,q);
    od;

    #
    # Finally, lift the generators of g, see the Monster paper for
    #  explanation of this
    #
    for x in newgens do
        #
        # The us and vs are the images of the Ts and Ds under x
        #
        us := List([1..k], i->
                   Product([1..k], j-> Ts[j]^IntFFE(x[i,j]))*
                   Product([1..k], j-> Ds[j]^IntFFE(x[i,j+k])));
        vs := List([1..k], i->
                   Product([1..k], j-> Ts[j]^IntFFE(x[i+k,j]))*
                   Product([1..k], j-> Ds[j]^IntFFE(x[i+k,j+k])));
        #
        # Now we want the vector fixed by the all the vs
        #
        o := One(vs[1]);
        vmos := List(vs, v->v-o);
        allvs := List([1..r^k], i->Concatenation(vmos{[1..k]}[i]));
        toprow := NullspaceMat(allvs)[1];
        #
        # Finally we make the rest of the matrix using the action of
        # the us -- this could be done more economically
        #
        Add( result, List(labels, l -> toprow*Product([1..k],j-> us[j]^IntFFE(l[j]))));
    od;
    return [Group(result), SubgroupNC(~[1],result{[1..2*k]})];
end;

##
##  This program is free software: you can redistribute it and/or modify
##  it under the terms of the GNU General Public License as published by
##  the Free Software Foundation, either version 3 of the License, or
##  (at your option) any later version.
##
##  This program is distributed in the hope that it will be useful,
##  but WITHOUT ANY WARRANTY; without even the implied warranty of
##  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##  GNU General Public License for more details.
##
##  You should have received a copy of the GNU General Public License
##  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

