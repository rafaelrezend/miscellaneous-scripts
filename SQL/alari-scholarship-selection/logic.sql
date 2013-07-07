select idStudent,
       SUM( hourCourse * mark ) / SUM( hourCourse ) AS WeightedAvg
from
(
  SELECT t.*,
  case when @idStudent<>t.idStudent
    then @cumSum:=hourCourse
    else case when @cumSum<30
            then @cumSum:=@cumSum+hourCourse
            else @cumSum:=-1
            end
  end as cumSum,
  @idStudent:=t.idStudent
  FROM `test` t,
  (select @idStudent:=0,@cumSum:=0) r
  order by idStudent, ABS(mark) desc
) t
where t.cumSum > 0
group by idStudent;