# ruby2.3.3 - 2.6.5
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

# TODO: 提高代码可复用性
class HuaweiCloudIMA
    attr_accessor :mainAccountName, :accessKeyId, :accessSecretKey

    def initialize **accountAttrs
        @mainAccountName = accountAttrs[:mainAccountName] 
        @accessKeyId     = accountAttrs[:accessKeyId]
        @accessSecretKey = accountAttrs[:accessSecretKey]
    end
    
    def huaweiCloudBalanceInfo
        digest = OpenSSL::Digest.new 'sha256'

        host  = '根据所在区域选择，参考华为云API文档'
        path  = "/v1.0/imaID/customer/account-mgr/balances"
        contentType = 'application/json'
        queryDateTime = Time.now.utc.localtime('+00:00').strftime "%Y%m%dT%H%M%SZ"

        _HTTPRequestMethod    = 'GET'
        canonicalURI          = path + '/'
        canonicalQueryString  = ''
        canonicalHeaders      = "content-type:#{contentType}" + "\n" +
                                "host:#{host}"                + "\n" +
                                "x-sdk-date:#{queryDateTime}" + "\n"
        signedHeaders         = 'content-type;host;x-sdk-date'
        hexEncodeHashRequestPayload = digest.hexdigest ''
        canonicalRequest =
              _HTTPRequestMethod   + "\n" +
              canonicalURI         + "\n" +
              canonicalQueryString + "\n" +
              canonicalHeaders     + "\n" +
              signedHeaders        + "\n" +
              hexEncodeHashRequestPayload

        hashedCanonicalRequest = digest.hexdigest canonicalRequest
        algorithm       = 'SDK-HMAC-SHA256'
        requestDateTime = queryDateTime
        stringToSign =
            algorithm + "\n" +
            requestDateTime + "\n" +
            hashedCanonicalRequest

        hmacDigest      = OpenSSL::HMAC.new @accessSecretKey, digest
        huaWeiYunSign   = hmacDigest.update(stringToSign).to_s

        url      = URI('https://' + host + path)
        request  = Net::HTTP::Get.new url
        request['Host']          = host
        request['Content-Type']   = contentType
        request['X-sdk-date']    = queryDateTime
        request['Authorization'] = 
                algorithm        + ' ' +
                'Access='        + "#{@accessKeyId}" + ', ' +
                'SignedHeaders=' + signedHeaders + ', ' +
                'Signature='     + huaWeiYunSign

        https    = Net::HTTP.new url.host, url.port
        https.use_ssl = true
        response = https.request request
        response = response.body
        JSON.parse(response).merge mainAccountName: @mainAccountName
    end
end

AccountsInfo = [
    {
        mainAccountName: '******',
        accessKeyId:     '******',
        accessSecretKey: '******'
    },
    {
        mainAccountName: '******',
        accessKeyId:     '******',
        accessSecretKey: '******'
    }
]
balance = []
AccountsInfo.map do |accountInfo|
    account = HuaweiCloudIMA.new accountInfo
    balance << account.huaweiCloudBalanceInfo
end
puts balance.to_json