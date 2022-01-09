-- UTF-8

poke(0X5F5C, 8) poke(0X5F5D, 3) -- 키입력 딜레이 설정

t=0
mx=1 my=1 -- 맵 배치할 좌표(좌상단)
cx=1 cy=1 -- 커서의 타일 좌표
tw=12 th=12 -- 맵 타일 칸 수 w/h(최대 15)
md={} -- 맵의 모든 칸 데이타(0~3)
csr={} -- 커서 obj
eff={} -- 이펙트 데이타

-- 임시 퍼즐 데이타
pz1={}
pz1[1]= {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
pz1[2]= {0,0,0,0,0,1,1,1,1,1,0,0,0,0,0}
pz1[3]= {0,0,0,1,1,1,1,1,1,1,1,1,0,0,0}
pz1[4]= {0,0,1,1,1,1,1,1,1,1,1,1,1,0,0}
pz1[5]= {0,0,1,1,1,1,1,1,1,1,1,1,1,0,0}
pz1[6]= {0,1,1,1,0,1,1,1,1,1,1,1,1,1,0}
pz1[7]= {0,1,1,0,0,0,1,1,1,0,0,0,0,1,0}
pz1[8]= {0,1,1,1,0,1,1,1,0,0,1,0,0,1,0}
pz1[9]= {0,1,1,1,1,1,1,0,0,1,1,1,0,1,0}
pz1[10]={0,1,0,1,1,1,0,0,0,0,1,0,0,1,0}
pz1[11]={0,0,1,0,0,0,0,0,0,0,0,0,1,0,0}
pz1[12]={0,0,1,0,0,0,0,0,0,0,0,0,1,0,0}
pz1[13]={0,0,0,1,1,0,0,0,0,0,1,1,0,0,0}
pz1[14]={0,0,0,0,0,1,1,1,1,1,0,0,0,0,0}
pz1[15]={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
pz2={}
pz2[1]= {0,0,1,1,1,1,1,1,0,0}
pz2[2]= {0,1,1,1,1,1,1,1,1,0}
pz2[3]= {0,1,1,1,1,1,1,1,1,0}
pz2[4]= {0,1,1,0,0,0,0,1,1,0}
pz2[5]= {0,1,0,1,0,0,1,0,1,0}
pz2[6]= {0,1,0,0,0,0,0,0,1,0}
pz2[7]= {0,1,0,0,1,1,0,0,1,0}
pz2[8]= {0,0,1,0,0,0,0,1,0,0}
pz2[9]= {0,1,1,1,1,1,1,1,1,0}
pz2[10]={1,1,1,1,1,1,1,1,1,1}
pz4={}
pz4[1]= {0,0,1,0,0}
pz4[2]= {0,1,1,1,0}
pz4[3]= {1,1,0,1,1}
pz4[4]= {0,1,1,1,0}
pz4[5]= {0,0,1,0,0}

-- 퍼즐 가로/세로줄 숫자값 계산해서 기록(출력 및 비교용)
-- #pz_h = 퍼즐 줄 수, #pz_v = 퍼즐 행 수
pz_h={} pz_v={}
pz_h2={} pz_v2={} -- 매치데이타(줄 숫자가 칸 찍은 형태와 맞는지)

-- 공용 함수들
function rou(n) return flr(n+.5) end -- 반올림
function flick() return flr(t/8)%2==0 end -- 깜빡이 신호

function _init()
	pz_init(pz2)
	csr.x=64
	csr.y=64
	csr.tx=0
	csr.ty=0
end

function _update60()
	i_key()
end

-- 퍼즐 데이타 초기화
function pz_init(pz)

	-- 퍼즐 데이타에 맞춰서 맵 크기, 기준 좌표 설정
	tw=#pz[1]
	th=#pz
	mx+=(15-tw)*3
	my+=(15-th)*3

	-- 맵 데이타 0 채우기
	for i=1,th do
		md[i]={}
		for j=1,tw do
			md[i][j]=0
			--md[i][j]=pz[i][j] -- 답안지 미리보기(개발용)
		end
	end

	init_pz_num(pz)

	-- 매치데이타 초기화 + 매칭 검사 1회 돌려서 기록
	for i=1,tw do upd_matchdata(i,1) end
	for i=1,th do upd_matchdata(1,i) end
end

function _draw()
	t+=1
	cls(0)

	dr_map()
	--dr_num1(md) -- 실시간 계산: md(화면 상태대로), pz(퍼즐 정보대로)
	dr_num2() -- pz_h, pz_v 값 출력
	dr_cursor()
	dr_eff()

	-- 시계추
	do
		local x1,y1=114,100
		local c,s=cos(t/60),abs(sin(t/60))
		local x2,y2=x1+c*8,y1+10+s*4
	  line(x1,y1,x2,y2,5)
		circfill(x2,y2,3,5)
		t_timer(x1-12,y1+20)
	end

	--?"▒nemonemo v0.1",2,120,6
	t_info()

	if(chk_clear()) dr_clear()
	--dr_gameover()
end

-- 클리어 여부 판별(가로/세로줄 숫자가 모두 녹색이면 클리어)
function chk_clear()
	local c=0
	for i=1,#pz_h2 do c+=pz_h2[i] end
	for i=1,#pz_v2 do c+=pz_v2[i] end
	return #pz_h2+#pz_v2==c
end

-- 키 입력
function i_key()

	if(btnp(0)) cx-=1
	if(btnp(1)) cx+=1
	if(btnp(2)) cy-=1
	if(btnp(3)) cy+=1
	cx=max(1,min(cx,tw))
	cy=max(1,min(cy,th))

	local v=md[cy][cx]
	-- x:fill
	if btnp(5) then
		if v==1 then md[cy][cx]=0
		else
			md[cy][cx]=1
			add_eff(cx,cy)
		end
		upd_matchdata(cx,cy)
	end
	-- z:marking
	if btnp(4) then
		if v==0 or v==1 then md[cy][cx]=2
		--elseif v==2 then md[cy][cx]=3
		else md[cy][cx]=0 end
	end
end

-- 칸 칠할 때 이펙트
function add_eff(cx,cy) add(eff,{cx,cy,0}) end

-- 이펙트 그리기
eff_c={7,7,10,10,9,4,8,2}
function dr_eff(cx,cy)
	if(#eff<1) return

	local function box(cx,cy,t)
		local x,y=mx+cx*6-3,my+cy*6-3
		local r=2+rou(sqrt(t)*1.7)
		circ(x,y,r,eff_c[1+flr(t*.6)])
		--rect(x-d,y-d,x+6+d,y+6+d,eff_c[1+flr(t*.6)])
	end

	for i=1,#eff do
		local b=eff[i]
		box(b[1],b[2],b[3])
		eff[i][3]+=1
	end

	for i in all(eff) do
		if i[3]>15 then del(eff,i) end
	end

end

-- 테스트로 찍어보는 글자
function t_info()
	--print("\f7by \f8🐱\f7seimon",x,y)
	--print("\f9⬆️⬇️⬅️➡️\f6move")
	--?"\fc❎\f6fill \fe🅾️\f6x",2,114
	?"\f5▒\f5nemonemo v0.1",2,114
	?"\fc❎\f6fill \fe🅾️\f6x \f9⬆️⬇️⬅️➡️\f6move",2,120
end

-- 타이머 m:ss.s
function t_timer(x,y)
	local t=time()
	local s=t%60
	local s1=flr(s)
	--local s2=flr((s-s1)*10)
	local m=max(0,flr(t/60))
	if (s1<10) s1="0"..s1
	--?"\f4⧗\f6"..m..":"..s1.."."..s2,x,y
	?"\f4⧗\f6"..m..":"..s1,x,y
end

function dr_map()
	for i=1,th do
		for j=1,tw do
			local s=md[i][j]
			if s==1 then -- 금 반짝이
				if flr(i*.7+j*1.5)==flr((t/3)%120) then s=4 end
			end
			spr(s,mx+j*6-6,my+i*6-6)
		end
	end
	-- 5칸마다 점(커서랑 겹치면 안찍음)
	for i=1,1+flr(th/5) do
		local y=my+(i-1)*6*5-1
		for j=1,1+flr(tw/5) do
			local x=mx+(j-1)*6*5-1
			if abs(csr.x-x+3)>6 or abs(csr.y-y+3)>6 then
				rect(x,y,x+2,y+2,0)
				rect(x+1,y+1,x+1,y+1,4)
			end
		end
	end
end

-- 커서 그리기(모션 포함)
function dr_cursor()
	csr.tx=mx+cx*6-7
	csr.ty=my+cy*6-7
	local sx=(csr.tx-csr.x)*.45
	local sy=(csr.ty-csr.y)*.45
	csr.x=csr.x+sx
	csr.y=csr.y+sy

	local x0=rou(csr.x) y0=rou(csr.y)
	local x1=csr.tx y1=csr.ty
	local w=8

	--rect(x0,y0,x0+w,y0+w,c) -- 따라가는 잔상
	--rect(x1,y1,x1+w,y1+w,c)
	--line(x1+w+1,y1+1,x1+w+1,y1+w,0)
	--line(x1+1,y1+w+1,x1+w+1,y1+w+1,0)

	local x2=min(x0,x1) y2=min(y0,y1)
	local x3=max(x0+w,x1+w) y3=max(y0+w,y1+w)

	-- 점선(좌상)
	dr_dotline_h(mx-3,y2+4,x2-2,11,1)
	dr_dotline_v(x3-4,my-3,y2-2,11,1)

	-- 커서
	rect(x2,y2,x3,y3,11)
	line(x3+1,y2+1,x3+1,y3+1,0)
	line(x2+1,y3+1,x3+1,y3+1,0)

	--점선(우하)
	dr_dotline_h(x3+1,y2+4,mx+tw*6+2,11,-1)
	dr_dotline_v(x3-4,y3+1,my+th*6+2,11,-1)
end

-- 점선(가로)
function dr_dotline_h(x1,y1,x2,c,d)
	local w=x2-x1
	if (w<5) return
	for i=0,flr(w/3)-1 do
		local x=x1+i*3+2+(t/5)%3*d
		line(x+1,y1+1,x+1,y1+1,0)
		line(x,y1,x,y1,c)
	end
end

-- 점선(세로)
function dr_dotline_v(x1,y1,y2,c,d)
	local h=y2-y1
	if (h<5) return
	for i=0,flr(h/3)-1 do
		local y=y1+i*3+2+(t/5)%3*d
		line(x1+1,y+1,x1+1,y+1,0)
		line(x1,y,x1,y,c)
	end
end

-- 숫자 테이블 정리해서 기록 -> pz_h, pz_v
function init_pz_num(data)
	for i=1,th do
		pz_h[i]=t_to_nums(data[i])
	end
	for i=1,tw do
		local t={}
		for j=1,th do t[j]=data[j][i] end
		pz_v[i]=t_to_nums(t)
	end
end

-- 숫자 그리기(매프레임 계산해서)
function dr_num1(data)
	for i=1,th do
		dr_numset_h(t_to_nums(data[i]),mx+tw*6+3,my+i*6-5,5) -- 오른쪽
	end
	for i=1,tw do
		local t={}
		for j=1,th do t[j]=data[j][i] end
		dr_numset_v(t_to_nums(t),mx+i*6-4,my+th*6+2,5) -- 아래
	end
end

-- 숫자 그리기(퍼즐 테이블에 기록된 값 x 매치데이타)
function dr_num2()
	for i=1,th do
		local c=5
		if(pz_h2[i]==1) c=3
		dr_numset_h(pz_h[i],mx+tw*6+3,my+i*6-5,c) -- 오른쪽
	end
	for i=1,tw do
		local c=5
		if(pz_v2[i]==1) c=3
		dr_numset_v(pz_v[i],mx+i*6-4,my+th*6+2,c) -- 아래
	end
end

-- 숫자 테이블 1개 받아 찍기(아래)
function dr_numset_v(t,x,y,c)
	if #t==0 then ?0,x,y,c
	else
		for i=1,#t do
			local n=t[i]
			if n==11 then
				?"|",x-1,y,c
				?"|",x+1,y,c
			elseif n>9 then
				?"|",x-2,y,c
				?n%10,x+1,y,c
			elseif n==1 then
				?"|",x,y,c
			else
				?t[i],x,y,c
			end
			y+=6
		end
	end
end

-- 숫자 테이블 1개 받아 찍기(오른쪽)
function dr_numset_h(t,x,y,c)
	if #t==0 then ?0,x,y,c
	else
		for i=1,#t do
			local n=t[i]
			if n>9 then
				?"|",x-1,y,c
				if n%10==1 then ?"|",x+1,y,c
				else
					?n%10,x+2,y,c
					x+=2
				end
			else
				if n==1 then
					?"|",x-1,y,c
					x-=2
				else
					?n,x,y,c
				end
			end
			x+=6
		end
	end
end

-- 정보 테이블을 숫자 테이블로 변환(0,1만 사용)
-- 0111010 -> 3,1
function t_to_nums(t)

	-- 최적화 가능함(이 함수 제거) ***********
	local function v0or1(n)
		if n==1 then return 1 else return 0 end
	end

	local tt={} -- 최종 테이블
	local cn=v0or1(t[1]) -- 카운트중인 숫자
	local cc=1 -- 카운트 횟수

	for i=2,#t do
		local n=v0or1(t[i])
		if cn==n then
			cc+=1
			if i==#t and n==1 then tt[#tt+1]=cc end
		else
			if n==0 then tt[#tt+1]=cc
			elseif n==1 and i==#t then tt[#tt+1]=1 end
			cn=n
			cc=1
		end
	end

	return tt
end

-- 타일 찍으면 매치데이타 업데이트
-- 커서 좌표의 행렬만 비교해서 업데이트(정답이 아니어도 겉보기에 맞으면 됨)
function upd_matchdata(x1,y1)
	-- 행
	local t1=t_to_nums(md[y1])
	local t2=pz_h[y1]
	local m=0 c=0
	if #t1==#t2 then
		for i=1,#t1 do
			if(t1[i]==t2[i]) c+=1
		end
		if(c==#t1) m=1
	end
	pz_h2[y1]=m
	-- 열
	local tt={}
	for i=1,th do
		tt[i]=md[i][x1]
	end
	local t1=t_to_nums(tt)
	local t2=pz_v[x1]
	local m=0 c=0
	if #t1==#t2 then
		for i=1,#t1 do
			if(t1[i]==t2[i]) c+=1
		end
		if(c==#t1) m=1
	end
	pz_v2[x1]=m
end






-- 스테이지 클리어하면 이것을 찍어줍시댜
function dr_clear()
	local x=64 y=55 w=96 h=36
	y+=48 -- 임시로 화면 하단에 찍어보자 **********
	local x1=x-w/2 y1=y-h/2
	local x2=x+w/2 y2=y+h/2
	rectfill(x1,y1,x2,y2,0)
	rect(x1+1,y1+1,x2-1,y2-1,12)
	?"s t a g e  c l e a r",x-39,y1+10,12
	?""
	--?"\fc❎\f6next \fe🅾️\f6exit",x-25,y1+22
	?"\fe🅾️\f6exit",x-11,y1+22
end

function dr_gameover()
	local x=64 y=55 w=96 h=36
	local x1=x-w/2 y1=y-h/2
	local x2=x+w/2 y2=y+h/2
	rectfill(x1,y1,x2,y2,0)
	rect(x1+1,y1+1,x2-1,y2-1,8)
	local txt=""
	if flick() then txt="g a m e  o v e r" end
	?txt,x-31,y1+10,8
	?""
	?"\fc❎\f6restart \fe🅾️\f6exit",x-31,y1+22
end