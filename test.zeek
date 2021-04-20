  
@load base/frameworks/sumstats

event http_reply (c: connection, version: string, code: count, reason: string)
{
	if(code==404)
	{
		SumStats::observe("404", SumStats::Key($host=c$id$orig_h), SumStats::Observation($num=1));
		SumStats::observe("uniURL404", SumStats::Key($host=c$id$orig_h), SumStats::Observation($str=c$http$uri));
	}
	SumStats::observe("response", SumStats::Key($host=c$id$orig_h), SumStats::Observation($num=1));
}

event zeek_init()
{
	local r1=SumStats::Reducer($stream="404", $apply=set(SumStats::SUM)); # if the count of 404 response > 2
	local r2=SumStats::Reducer($stream="uniURL404", $apply=set(SumStats::UNIQUE)); # the unique count of url response 404
	local r3=SumStats::Reducer($stream="response", $apply=set(SumStats::SUM));  # the count of all response

	SumStats::create([$name="ymc_scanner", $epoch=10min, $reducers=set(r1,r2,r3), 
					  $epoch_result(ts:time, key: SumStats::Key, result: SumStats::Result)={local s1=result["404"]; local s2=result["uniURL404"]; local s3=result["response"];
																							if (s1$sum>2 && 1.0*s1$sum/s3$sum>0.2 && 1.0*s2$unique/s1$sum>0.5) # three cases
																							{
																								print fmt("%s is a scanner with %d scan attemps on %d urls", key$host, s1$sum, s2$unique);
																							}
																							}]);
}
