// iyzico-helper.js
// İyzico API ile doğrudan etkileşimde bulunacak özel bir modül

const crypto = require('crypto-js');
const https = require('https');
const querystring = require('querystring');

/**
 * İyzico API bağlantı ve imza oluşturma yardımcısı
 * İyzico'nun resmi örneklerinden uyarlanmıştır
 */
class IyzicoHelper {
  constructor(apiKey, secretKey, baseUrl) {
    this.apiKey = apiKey;
    this.secretKey = secretKey;
    this.baseUrl = baseUrl || 'https://sandbox-api.iyzipay.com';
    this.headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json'
    };
  }

  /**
   * İyzico API için authorization header'ı oluşturur
   */
  generateAuthorizationHeader(uri, body, randomString) {
    try {
      if (!randomString) {
        randomString = this.generateRandomString();
      }

      let payload = this.apiKey + randomString + this.secretKey;
      if (body && body.length > 0) {
        payload += body;
      }

      // İyzico'nun beklediği formatta HMAC-SHA1 imzası oluştur
      const hash = crypto.HmacSHA1(payload, this.secretKey).toString(crypto.enc.Base64);
      
      // Debug için log
      console.log('[IyzicoHelper] İmza oluşturuldu:', {
        apiKey: this.apiKey.substring(0, 10) + '...',
        randomString: randomString,
        hashResult: hash,
        bodyLength: body ? body.length : 0
      });

      return {
        authorization: `IYZWS ${this.apiKey}:${hash}`,
        randomString: randomString
      };
    } catch (error) {
      console.error('[IyzicoHelper] İmza oluşturma hatası:', error);
      throw error;
    }
  }

  /**
   * İyzico API isteği gönderir
   */
  async request(endpoint, requestData) {
    return new Promise((resolve, reject) => {
      try {
        const body = JSON.stringify(requestData);
        const randomString = this.generateRandomString();
        
        const { authorization } = this.generateAuthorizationHeader(endpoint, body, randomString);
        
        // İstek header'larını hazırla
        const headers = {
          ...this.headers,
          'Authorization': authorization,
          'x-iyzi-rnd': randomString
        };

        console.log('[IyzicoHelper] İstek detayları:', {
          url: this.baseUrl + endpoint,
          method: 'POST',
          headers: Object.keys(headers).reduce((obj, key) => {
            if (key !== 'Authorization') {
              obj[key] = headers[key];
            } else {
              obj[key] = 'HIDDEN';
            }
            return obj;
          }, {}),
          bodyLength: body.length
        });

        // HTTPS isteği oluştur
        const requestOptions = {
          method: 'POST',
          headers: headers
        };
        
        const req = https.request(this.baseUrl + endpoint, requestOptions, (res) => {
          let responseData = '';
          
          res.on('data', (chunk) => {
            responseData += chunk;
          });
          
          res.on('end', () => {
            try {
              const parsedData = JSON.parse(responseData);
              console.log('[IyzicoHelper] API yanıtı:', {
                status: res.statusCode,
                responseStatus: parsedData.status,
                errorCode: parsedData.errorCode,
                errorMessage: parsedData.errorMessage
              });
              
              resolve({ statusCode: res.statusCode, data: parsedData });
            } catch (error) {
              console.error('[IyzicoHelper] Yanıt işleme hatası:', error);
              reject(error);
            }
          });
        });
        
        req.on('error', (error) => {
          console.error('[IyzicoHelper] İstek hatası:', error);
          reject(error);
        });
        
        // İstek gövdesini gönder
        req.write(body);
        req.end();
      } catch (error) {
        console.error('[IyzicoHelper] Genel hata:', error);
        reject(error);
      }
    });
  }

  /**
   * Rastgele bir string oluşturur
   */
  generateRandomString(length = 8) {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      result += characters.charAt(Math.floor(Math.random() * characters.length));
    }
    return result;
  }
}

module.exports = IyzicoHelper;
